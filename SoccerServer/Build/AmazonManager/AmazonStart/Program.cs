using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

using Amazon;
using Amazon.EC2;
using Amazon.EC2.Model;
using Amazon.SimpleDB;
using Amazon.SimpleDB.Model;
using Amazon.S3;
using Amazon.S3.Model;
using Amazon.Route53;
using Amazon.Route53.Model;
using System.Net;
using Amazon.ElasticLoadBalancing;
using Amazon.ElasticLoadBalancing.Model;
using CommandLine;

/* NOTES "To my beloved future self":
 * 
 * 1) eu-west in hardcoded.
 * 2) ConfigureLoadBalancer asumes that the name of the instances to add starts with "http"
 */

namespace AmazonStart
{
    // http://commandline.codeplex.com
    class Options
    {
        [Option("p", "project", Required = false, HelpText = "Project name as set in AWS tag")]
        public string Project = "UnusualSoccer";

        [Option("b", "loadbalancername", Required = false, HelpText = "Load balancer name as assigned in AWS")]
        public string LoadBalancerName = "TheBalancer";

        [Option("h", "hostedzone", Required = false, HelpText = "Hosted zone Name")]
        public string HostedZone = "unusualsoccer.com";

        [Option("w", "waitforelb", Required = false, HelpText = "Wait for all instances to be InService")]
        public bool WaitForELB = false;
    }

    class Program
    {
        static private Options OPTIONS = new Options();

        private const string EC2_SERVICE_URL = "https://ec2.eu-west-1.amazonaws.com";
        private const string ELB_SERVICE_URL = "https://elasticloadbalancing.eu-west-1.amazonaws.com";
       
        static public void Main(string[] args)
        {
            if (!new CommandLineParser().ParseArguments(args, OPTIONS))
            {
                Console.Write("Wrong options...");
            }
            else
            {
                if (OPTIONS.WaitForELB)
                    WaitForAllInstancesInELB();
                else
                    ProjectStart();
            }
        }

        static private void ProjectStart()
        {
            // Sobre las regiones: http://aws.amazon.com/articles/3912#endpoints
            AmazonEC2Config ec2Config = new AmazonEC2Config() { ServiceURL = EC2_SERVICE_URL };
            AmazonElasticLoadBalancingConfig elbConfig = new AmazonElasticLoadBalancingConfig() { ServiceURL = ELB_SERVICE_URL };

            Console.WriteLine("Using region eu-west for all operations.\n");

            AmazonRoute53 r53 = AWSClientFactory.CreateAmazonRoute53Client();
            AmazonEC2 ec2 = AWSClientFactory.CreateAmazonEC2Client(ec2Config);
            AmazonElasticLoadBalancing elb = AWSClientFactory.CreateAmazonElasticLoadBalancingClient(elbConfig);

            // All operations require the ID and can't operate with just the name
            string hostedZoneID = GetHostedZoneID(r53);

            // Listamos todos los RecordSets de tipo "CNAME", levantamos y listamos todas nuestras instancias en funcionamiento,
            // generamos la lista de cambios comparando con el PublicDNS de las instancias y aplicamos los cambios
            var recordSets = ListRecordSets(r53, hostedZoneID);
            var runningInstances = StartInstances(ec2);
            var changeList = GenerateChangeList(ec2, recordSets, runningInstances);

            ApplyResourceRecordSetsChanges(changeList, hostedZoneID);

            // Verificamos contra el DNS. Este metodo no retorna hasta que todos los cambios son visibles en el DNS desde nuestra maquina. 
            // Internamente Volvera a pedir toda la lista de ResourceRecordSets con los cambios ya aplicados.
            VerifyChanges(ec2, r53, hostedZoneID, runningInstances);

            // We remove the old instances, add the new ones
            ConfigureLoadBalancer(elb, runningInstances);

            // We wait for all the instances to pass the 2 AWS health checks. This makes sure that the SO is started.
            WaitForHealthCheck(ec2, runningInstances);

            Console.WriteLine("\nProjectStart Done!.\n\n");
        }

        static private string GetHostedZoneID(AmazonRoute53 r53)
        {
            var result = r53.ListHostedZones(new ListHostedZonesRequest());

            foreach (var zone in result.ListHostedZonesResult.HostedZones)
            {
                if (zone.Name == OPTIONS.HostedZone + ".")
                    return zone.Id;
            }
            return null;
        }

        static private void WaitForAllInstancesInELB()
        {
            AmazonElasticLoadBalancingConfig elbConfig = new AmazonElasticLoadBalancingConfig() { ServiceURL = ELB_SERVICE_URL };
            AmazonElasticLoadBalancing elb = AWSClientFactory.CreateAmazonElasticLoadBalancingClient(elbConfig);

            bool bAllReady = false;

            do
            {
                Console.WriteLine("\nWaiting for all instances to be InService...");

                var healthResponse = elb.DescribeInstanceHealth(new DescribeInstanceHealthRequest() { LoadBalancerName = "TheBalancer" });
                bAllReady = healthResponse.DescribeInstanceHealthResult.InstanceStates.All(inst => inst.State == "InService");

                if (!bAllReady)
                    System.Threading.Thread.Sleep(10000);

            } while (!bAllReady);

            Console.WriteLine("WaitForAllInstancesInELB Done!.\n\n");
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
                PrintR53Exception(ex);
            }

            Console.WriteLine("{0} ResourceRecordSets 'CNAME' retrieved", ret.Count());

            foreach (ResourceRecordSet rss in ret)
            {
                Console.WriteLine("ResourceRecordSet {0} with value {1}", rss.Name, rss.ResourceRecords[0].Value);
            }
            Console.WriteLine("");

            return ret;
        }

        static private List<RunningInstance> StartInstances(AmazonEC2 ec2)
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
                    if (reservationInstance.RunningInstance.Count != 1)
                        continue;

                    RunningInstance instance = reservationInstance.RunningInstance[0];

                    var instanceName = GetInstanceName(instance);

                    if (instanceName == null)
                    {
                        Console.WriteLine("Ignoring instance {0} without name", instance.InstanceId);
                        continue;
                    }
                    if (!IsInstanceInProject(instance))
                    {
                        Console.WriteLine("Ignoring instance {0} not in project {1}", instanceName, OPTIONS.Project);
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
            Console.WriteLine("\nGenerating change list for {0} running instances:", runningInstances.Count());

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
                PrintEC2Exception(ex);
            }

            return changes;
        }

        static private string GetInstanceName(RunningInstance instance)
        {
            var tagWithName = instance.Tag.Find(tag => tag.Key == "Name");
            return tagWithName == null ? null : tagWithName.Value;
        }

        static private bool IsInstanceInProject(RunningInstance instance)
        {
            var tagWithKey = instance.Tag.Find(tag => tag.Key == "Project");
            return tagWithKey == null ? false : tagWithKey.Value == OPTIONS.Project;
        }

        static private ResourceRecordSet GetResourceRecordSetForInstanceName(string instanceName, IEnumerable<ResourceRecordSet> resourceRecordSets)
        {
            return resourceRecordSets.SingleOrDefault(rrs => rrs.Name.StartsWith(instanceName.ToLower()));
        }

        static private void AddChangesForInstance(RunningInstance instance, ResourceRecordSet rss, List<Change> changes)
        {
            ResourceRecordSet creationRecordSet  = null;
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
                AmazonRoute53 r53 = AWSClientFactory.CreateAmazonRoute53Client();

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
            Console.WriteLine("\n\nVerifying that changes are visible from our computer by querying the DNS:\n");

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

            Console.WriteLine("All ready!");
        }


        static private ResourceRecordSet CloneRecordSet(ResourceRecordSet o)
        {
            return new ResourceRecordSet().WithAliasTarget(o.AliasTarget).WithName(o.Name).WithResourceRecords(o.ResourceRecords).
                                           WithSetIdentifier(o.SetIdentifier).WithTTL(o.TTL).WithType(o.Type);
        }

        static private void ConfigureLoadBalancer(AmazonElasticLoadBalancing elb, List<RunningInstance> runningInstances)
        {
            Console.WriteLine("\nConfiguring the Load Balancer '{0}'...", OPTIONS.LoadBalancerName);

            var request = new DescribeLoadBalancersRequest() { LoadBalancerNames = new List<string>() { OPTIONS.LoadBalancerName } };

            // Sacamos todas las instancias que esten out of service
            var healthResponse = elb.DescribeInstanceHealth(new DescribeInstanceHealthRequest() { LoadBalancerName = OPTIONS.LoadBalancerName });
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
                    LoadBalancerName = OPTIONS.LoadBalancerName
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
                    LoadBalancerName = OPTIONS.LoadBalancerName
                });
            }

            Console.WriteLine("Load Balancer ready...", OPTIONS.LoadBalancerName);
        }

        static private void PrintEC2Exception(AmazonEC2Exception ex)
        {
            if (ex.ErrorCode != null && ex.ErrorCode.Equals("AuthFailure"))
            {
                Console.WriteLine("The account you are using is not signed up for Amazon EC2.");
                Console.WriteLine("You can sign up for Amazon EC2 at http://aws.amazon.com/ec2");
            }
            else
            {
                Console.WriteLine("Caught Exception: " + ex.Message);
                Console.WriteLine("Response Status Code: " + ex.StatusCode);
                Console.WriteLine("Error Code: " + ex.ErrorCode);
                Console.WriteLine("Error Type: " + ex.ErrorType);
                Console.WriteLine("Request ID: " + ex.RequestId);
                Console.WriteLine("XML: " + ex.XML);
            }
        }

        static private void PrintR53Exception(AmazonRoute53Exception ex)
        {
            if (ex.ErrorCode != null && ex.ErrorCode.Equals("AuthFailure"))
            {
                Console.WriteLine("The account you are using is not signed up for Amazon Route 53.");
            }
            else
            {
                Console.WriteLine("Caught Exception: " + ex.Message);
                Console.WriteLine("Response Status Code: " + ex.StatusCode);
                Console.WriteLine("Error Code: " + ex.ErrorCode);
                Console.WriteLine("Error Type: " + ex.ErrorType);
                Console.WriteLine("Request ID: " + ex.RequestId);
            }
        }

        static private void PrintS3Exception(AmazonS3Exception ex)
        {
            if (ex.ErrorCode != null && (ex.ErrorCode.Equals("InvalidAccessKeyId") || ex.ErrorCode.Equals("InvalidSecurity")))
            {
                Console.WriteLine("Please check the provided AWS Credentials.");
                Console.WriteLine("If you haven't signed up for Amazon S3, please visit http://aws.amazon.com/s3");
            }
            else
            {
                Console.WriteLine("Caught Exception: " + ex.Message);
                Console.WriteLine("Response Status Code: " + ex.StatusCode);
                Console.WriteLine("Error Code: " + ex.ErrorCode);
                Console.WriteLine("Request ID: " + ex.RequestId);
                Console.WriteLine("XML: " + ex.XML);
            }
        }
        
    }
}