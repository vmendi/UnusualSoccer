using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using Amazon;
using Amazon.EC2;
using Amazon.EC2.Model;
using Amazon.ElasticLoadBalancing;
using Amazon.ElasticLoadBalancing.Model;
using Amazon.Route53;
using Amazon.Route53.Model;

/* 
 * NOTES "To my beloved future self":
 * 
 * 1) eu-west in hardcoded.
 * 2) ConfigureLoadBalancer asumes that the name of the instances to add starts with "http"
 * 
 */
namespace AmazonCmdlet
{   
    public class Core
    {
        private const string EC2_SERVICE_URL = "https://ec2.eu-west-1.amazonaws.com";
        private const string ELB_SERVICE_URL = "https://elasticloadbalancing.eu-west-1.amazonaws.com";

        private const string AWS_ACCESS_KEY = "AKIAJ3LOZJQHKEPHXZDQ";
        private const string AWS_SECRET_KEY = "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";
        
        static public IEnumerable<string> StartProject(string project, string loadBalancerName, string hostedZone)
        {
            // About regions: http://aws.amazon.com/articles/3912#endpoints
            AmazonEC2Config ec2Config = new AmazonEC2Config() { ServiceURL = EC2_SERVICE_URL };
            AmazonElasticLoadBalancingConfig elbConfig = new AmazonElasticLoadBalancingConfig() { ServiceURL = ELB_SERVICE_URL };

            Console.WriteLine("Using region eu-west for all operations.\n");

            AmazonRoute53 r53 = AWSClientFactory.CreateAmazonRoute53Client(AWS_ACCESS_KEY, AWS_SECRET_KEY);
            AmazonEC2 ec2 = AWSClientFactory.CreateAmazonEC2Client(AWS_ACCESS_KEY, AWS_SECRET_KEY, ec2Config);
            AmazonElasticLoadBalancing elb = AWSClientFactory.CreateAmazonElasticLoadBalancingClient(AWS_ACCESS_KEY, AWS_SECRET_KEY, elbConfig);

            // Listamos y levantamos todas nuestras instancias asociadas al projecto
            var runningInstances = StartInstances(ec2, project);

            // Makes sure that Route53 is properly configured and running
            ConfigureDNS(ec2, r53, hostedZone, runningInstances);
            
            // Remove the old instances and add the new ones to the Load Balancer
            ConfigureLoadBalancer(elb, loadBalancerName, runningInstances);

            // Wait for all the instances to pass the 2 AWS health checks. This makes sure that the OS is started.
            WaitForHealthCheck(ec2, runningInstances);

            Console.WriteLine("\nStartProject Done!\n");

            return runningInstances.Select(r => GetInstanceName(r).ToLower() + "." + hostedZone);
        }


        static public void WaitAllInstancesInELB(string loadBalancerName)
        {
            AmazonElasticLoadBalancingConfig elbConfig = new AmazonElasticLoadBalancingConfig() { ServiceURL = ELB_SERVICE_URL };
            AmazonElasticLoadBalancing elb = AWSClientFactory.CreateAmazonElasticLoadBalancingClient(AWS_ACCESS_KEY, AWS_SECRET_KEY, elbConfig);

            bool bAllReady = false;

            do
            {
                Console.WriteLine("Waiting for all instances to be InService...");

                var healthResponse = elb.DescribeInstanceHealth(new DescribeInstanceHealthRequest() { LoadBalancerName = loadBalancerName });
                bAllReady = healthResponse.DescribeInstanceHealthResult.InstanceStates.All(inst => inst.State == "InService");

                if (!bAllReady)
                    System.Threading.Thread.Sleep(10000);

            } while (!bAllReady);

            Console.WriteLine("WaitAllInstancesInELB Done!\n");
        }

        static private void ConfigureDNS(AmazonEC2 ec2, AmazonRoute53 r53, string hostedZone, IEnumerable<RunningInstance> runningInstances)
        {
            // All operations require the ID and can't operate with just the name
            string hostedZoneID = GetHostedZoneID(r53, hostedZone);

            // Listamos todos los RecordSets de tipo "CNAME", generamos la lista de cambios comparando con el PublicDNS de las instancias y aplicamos los cambios.
            var recordSets = ListRecordSets(r53, hostedZoneID);
            var changeList = GenerateChangeList(ec2, recordSets, runningInstances);
            ApplyResourceRecordSetsChanges(changeList, hostedZoneID);

            // Verificamos contra el DNS. Este metodo no retorna hasta que todos los cambios son visibles en el DNS desde nuestra maquina. 
            // Internamente volvera a pedir toda la lista de ResourceRecordSets con los cambios ya aplicados.
            VerifyChanges(ec2, r53, hostedZoneID, runningInstances);
        }


        static private string GetHostedZoneID(AmazonRoute53 r53, string hostedZone)
        {
            var result = r53.ListHostedZones(new ListHostedZonesRequest());

            foreach (var zone in result.ListHostedZonesResult.HostedZones)
            {
                if (zone.Name == hostedZone + ".")
                    return zone.Id;
            }
            return null;
        }

        static private IEnumerable<ResourceRecordSet> ListRecordSets(AmazonRoute53 r53, string hostedZoneID)
        {
            Console.WriteLine("Listing ResourceRecordSets...\n");

            IEnumerable<ResourceRecordSet> ret = new List<ResourceRecordSet>();

            try
            {
                ListResourceRecordSetsRequest listRequest = new ListResourceRecordSetsRequest();
                listRequest.HostedZoneId = hostedZoneID;

                ListResourceRecordSetsResponse listResponse = r53.ListResourceRecordSets(listRequest);

                ret = listResponse.ListResourceRecordSetsResult.ResourceRecordSets.Where(rss => rss.Type == "CNAME");
            }
            catch (AmazonRoute53Exception ex)
            {
                ExceptionPrint.PrintR53Exception(ex);
            }

            Console.WriteLine("{0} ResourceRecordSets 'CNAME' retrieved", ret.Count());

            foreach (ResourceRecordSet rss in ret)
            {
                Console.WriteLine("ResourceRecordSet {0} with value {1}", rss.Name, rss.ResourceRecords[0].Value);
            }
            Console.WriteLine("");

            return ret;
        }

        static private List<RunningInstance> StartInstances(AmazonEC2 ec2, string project)
        {
            List<RunningInstance> runningInstances = new List<RunningInstance>();
            List<string> pendingInstancesIDs = new List<string>();
            List<string> stoppedInstancesIDs = new List<string>();

            DescribeInstancesResponse ec2Response = ec2.DescribeInstances(new DescribeInstancesRequest());
            Console.WriteLine("You have " + ec2Response.DescribeInstancesResult.Reservation.Count + " Amazon EC2 instance(s) in the region:");

            bool bAllReady = false;

            while (!bAllReady)
            {
                foreach (var reservationInstance in ec2Response.DescribeInstancesResult.Reservation)
                {
                    foreach (var instance in reservationInstance.RunningInstance)
                    {
                        var instanceName = GetInstanceName(instance);

                        if (instanceName == null)
                        {
                            Console.WriteLine("Ignoring instance {0} without name", instance.InstanceId);
                            continue;
                        }
                        if (!IsInstanceInProject(project, instance))
                        {
                            Console.WriteLine("Ignoring instance {0} not in project {1}", instanceName, project);
                            continue;
                        }

                        if (instance.InstanceState.Name == "pending")
                        {
                            Console.WriteLine("Instance {0} is PENDING. We will wait until ready.", instanceName);
                            pendingInstancesIDs.Add(instance.InstanceId);
                        }
                        else if (instance.InstanceState.Name == "stopped")
                        {
                            Console.WriteLine("Instance {0} is STOPPED. Starting it.", instanceName);
                            stoppedInstancesIDs.Add(instance.InstanceId);
                        }
                        else if (instance.InstanceState.Name == "running")
                        {
                            Console.WriteLine("Instance {0} is RUNNING.", instanceName);
                            runningInstances.Add(instance);
                        }
                        else
                        {
                            Console.WriteLine("Ignoring instance {0} in state {1}", instanceName, instance.InstanceState.Name);
                        }
                    }
                }

                if (stoppedInstancesIDs.Count != 0)
                {
                    var response = ec2.StartInstances(new StartInstancesRequest() { InstanceId = stoppedInstancesIDs });
                    pendingInstancesIDs.AddRange(stoppedInstancesIDs);
                    stoppedInstancesIDs.Clear();
                }

                if (pendingInstancesIDs.Count != 0)
                {
                    System.Threading.Thread.Sleep(10000);
                    var request = new DescribeInstancesRequest() { InstanceId = pendingInstancesIDs };
                    ec2Response = ec2.DescribeInstances(request);
                    pendingInstancesIDs.Clear();
                }
                else
                {
                    bAllReady = true;
                }
            }

            Console.WriteLine("StartInstances: All instances RUNNING!\n");

            return runningInstances;
        }

        static private void WaitForHealthCheck(AmazonEC2 ec2, IEnumerable<RunningInstance> runningInstances)
        {
            Console.WriteLine("\nWaiting for {0} instances health check...", runningInstances.Count());

            var pendingInstances = new List<RunningInstance>(runningInstances);

            while (pendingInstances.Count > 0)
            {
                var instanceIDs = new List<string>(pendingInstances.Select(r => r.InstanceId));
                var response = ec2.DescribeInstanceStatus(new DescribeInstanceStatusRequest() { InstanceId = instanceIDs });

                foreach (var status in response.DescribeInstanceStatusResult.InstanceStatus)
                {
                    var instance = pendingInstances.Single(i => i.InstanceId == status.InstanceId);

                    if (status.InstanceStatusDetail.Status == "ok" && status.SystemStatusDetail.Status == "ok")
                    {
                        Console.WriteLine("Instance {0} passed 2/2 tests", GetInstanceName(instance));
                        pendingInstances.Remove(instance);
                    }
                    else
                    {
                        Console.WriteLine("Instance {0} Failed! InstanceStatus: {1}, SystemStatus {2}", GetInstanceName(instance),
                                          status.InstanceStatusDetail.Status, status.SystemStatusDetail.Status);
                    }
                }

                if (pendingInstances.Count > 0)
                    System.Threading.Thread.Sleep(10000);
            }

            Console.WriteLine("Health check passed for all instances!");
        }

        static private List<Change> GenerateChangeList(AmazonEC2 ec2, IEnumerable<ResourceRecordSet> resourceRecordSets, IEnumerable<RunningInstance> runningInstances)
        {
            Console.WriteLine("Generating change list for {0} running instances:", runningInstances.Count());

            List<Change> changes = new List<Change>();

            try
            {
                foreach (var instance in runningInstances)
                {
                    var instanceName = GetInstanceName(instance);
                    var foundRRS = GetResourceRecordSetForInstanceName(instanceName, resourceRecordSets);

                    if (foundRRS != null)
                    {
                        if (instance.PublicDnsName != foundRRS.ResourceRecords.Single().Value)
                        {
                            Console.WriteLine("{0} will be updated to {1}", foundRRS.Name, instance.PublicDnsName);
                            AddChangesForInstance(instance, foundRRS, changes);
                        }
                        else
                            Console.WriteLine("{0} is already up to date", foundRRS.Name);
                    }
                    else
                    {
                        Console.WriteLine("Instance {0} has no entry in the record set. Creating it with value {1} ", instanceName, instance.PublicDnsName);
                        AddChangesForInstance(instance, null, changes);
                    }
                }
            }
            catch (AmazonEC2Exception ex)
            {
                ExceptionPrint.PrintEC2Exception(ex);
            }

            return changes;
        }

        static private string GetInstanceName(RunningInstance instance)
        {
            var tagWithName = instance.Tag.Find(tag => tag.Key == "Name");
            return tagWithName == null ? null : tagWithName.Value;
        }

        static private bool IsInstanceInProject(string project, RunningInstance instance)
        {
            var tagWithKey = instance.Tag.Find(tag => tag.Key == "Project");
            return tagWithKey == null ? false : tagWithKey.Value == project;
        }

        static private ResourceRecordSet GetResourceRecordSetForInstanceName(string instanceName, IEnumerable<ResourceRecordSet> resourceRecordSets)
        {
            return resourceRecordSets.SingleOrDefault(rrs => rrs.Name.StartsWith(instanceName.ToLower()));
        }

        static private void AddChangesForInstance(RunningInstance instance, ResourceRecordSet rss, List<Change> changes)
        {
            ResourceRecordSet creationRecordSet = null;
            var change = new Change();

            if (rss != null)
            {
                change.Action = "DELETE";
                change.ResourceRecordSet = rss;
                changes.Add(change);

                creationRecordSet = CloneRecordSet(rss);
            }
            else
            {
                creationRecordSet = new ResourceRecordSet();
                creationRecordSet.Type = "CNAME";
                creationRecordSet.TTL = 300;
                creationRecordSet.Name = GetInstanceName(instance).ToLower() + ".unusualsoccer.com";
            }

            creationRecordSet.ResourceRecords = new List<ResourceRecord>() { new ResourceRecord() { Value = instance.PublicDnsName } };

            change = new Change();
            change.Action = "CREATE";
            change.ResourceRecordSet = creationRecordSet;
            changes.Add(change);
        }

        static private void ApplyResourceRecordSetsChanges(List<Change> changes, string hostedZoneID)
        {
            if (changes.Count > 0)
            {
                AmazonRoute53 r53 = AWSClientFactory.CreateAmazonRoute53Client(AWS_ACCESS_KEY, AWS_SECRET_KEY);

                ChangeResourceRecordSetsRequest changeRequest = new ChangeResourceRecordSetsRequest();
                changeRequest.HostedZoneId = hostedZoneID;
                changeRequest.ChangeBatch = new ChangeBatch() { Changes = changes };

                Console.WriteLine("\nSending ChangeRequest with batch size {0}", changes.Count);

                ChangeResourceRecordSetsResponse changeResponse = r53.ChangeResourceRecordSets(changeRequest);

                Console.WriteLine("Operation is {0}", changeResponse.ChangeResourceRecordSetsResult.ChangeInfo.Status);

                var changeInfo = changeResponse.ChangeResourceRecordSetsResult.ChangeInfo;

                while (changeInfo.Status == "PENDING")
                {
                    System.Threading.Thread.Sleep(10000);

                    var getChangeResponse = r53.GetChange(new GetChangeRequest() { Id = changeInfo.Id });
                    changeInfo = getChangeResponse.GetChangeResult.ChangeInfo;

                    Console.WriteLine("Operation is {0}", changeInfo.Status);
                }
            }
        }

        static private void VerifyChanges(AmazonEC2 ec2, AmazonRoute53 r53, string hostedZoneID, IEnumerable<RunningInstance> runningInstances)
        {
            Console.WriteLine("\nVerifying that changes are visible from our computer by querying the DNS:\n");

            // We list the ResourceRecorSets again, after being INSYNC...
            IEnumerable<ResourceRecordSet> resourceRecordSets = ListRecordSets(r53, hostedZoneID);

            bool bAllReady = true;

            do
            {
                if (!bAllReady)
                    System.Threading.Thread.Sleep(10000);

                bAllReady = true;

                foreach (var instance in runningInstances)
                {
                    if (instance.InstanceState.Name != "running")
                        continue;

                    var instanceName = GetInstanceName(instance);
                    var foundRRS = GetResourceRecordSetForInstanceName(instanceName, resourceRecordSets);
                    var route53Value = foundRRS.ResourceRecords.Single().Value;

                    // Veamos si el cambio en el DNS ya es visible desde nuestra maquina
                    var host = Dns.GetHostEntry(foundRRS.Name);

                    if (host.HostName == route53Value)
                        Console.WriteLine("Is ready: {0} DNS matchs with {1}", foundRRS.Name, route53Value);
                    else
                    {
                        Console.WriteLine("NOT ready: {0} does not match with {1} ", foundRRS.Name, route53Value);
                        bAllReady = false;
                    }
                }

            } while (!bAllReady);

            Console.WriteLine("VerifyChanges: All ready!\n");
        }


        static private ResourceRecordSet CloneRecordSet(ResourceRecordSet o)
        {
            return new ResourceRecordSet().WithAliasTarget(o.AliasTarget).WithName(o.Name).WithResourceRecords(o.ResourceRecords).
                                           WithSetIdentifier(o.SetIdentifier).WithTTL(o.TTL).WithType(o.Type);
        }

        static private void ConfigureLoadBalancer(AmazonElasticLoadBalancing elb, string loadBalancerName, List<RunningInstance> runningInstances)
        {
            Console.WriteLine("\nConfiguring the Load Balancer '{0}'...", loadBalancerName);

            var request = new DescribeLoadBalancersRequest() { LoadBalancerNames = new List<string>() { loadBalancerName } };

            // Sacamos todas las instancias que esten out of service
            var healthResponse = elb.DescribeInstanceHealth(new DescribeInstanceHealthRequest() { LoadBalancerName = loadBalancerName });
            var instancesToRemove = new List<Instance>();
            var instancesInService = new List<Instance>();

            foreach (var instanceStates in healthResponse.DescribeInstanceHealthResult.InstanceStates)
            {
                if (instanceStates.State != "InService")
                {
                    instancesToRemove.Add(new Instance() { InstanceId = instanceStates.InstanceId });

                    Console.WriteLine("Will remove {0} from the Load Balancer", instanceStates.InstanceId);
                }
                else
                {
                    instancesInService.Add(new Instance() { InstanceId = instanceStates.InstanceId });
                }
            }

            if (instancesToRemove.Count > 0)
            {
                var deregisterResponse = elb.DeregisterInstancesFromLoadBalancer(new DeregisterInstancesFromLoadBalancerRequest()
                {
                    Instances = instancesToRemove,
                    LoadBalancerName = loadBalancerName
                });
            }

            // Añadimos de entre las runningInstances las que no estuvieran inService y se llamen "HTTP*"
            var instancesToAdd = new List<Instance>();

            foreach (var runningInst in runningInstances)
            {
                if (GetInstanceName(runningInst).ToLower().StartsWith("http") &&
                    !instancesInService.Any(inService => inService.InstanceId == runningInst.InstanceId))
                {
                    instancesToAdd.Add(new Instance() { InstanceId = runningInst.InstanceId });

                    Console.WriteLine("Will add {0} {1} to the Load Balancer", GetInstanceName(runningInst), runningInst.InstanceId);
                }
            }

            if (instancesToAdd.Count > 0)
            {
                // Ahora añádimos todas las que no estuvieran en servicio ya
                var registerReponse = elb.RegisterInstancesWithLoadBalancer(new RegisterInstancesWithLoadBalancerRequest()
                {
                    Instances = instancesToAdd,
                    LoadBalancerName = loadBalancerName
                });
            }

            Console.WriteLine("Load Balancer ready...", loadBalancerName);
        }
    }
}
