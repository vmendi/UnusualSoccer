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

namespace MainManager
{
    class Program
    {
        static public void Main(string[] args)
        {
            // Sobre las regiones: http://aws.amazon.com/articles/3912#endpoints
            AmazonEC2Config ec2Config = new AmazonEC2Config() { ServiceURL = "https://ec2.eu-west-1.amazonaws.com" };
            AmazonElasticLoadBalancingConfig elbConfig = new AmazonElasticLoadBalancingConfig() { ServiceURL = "https://elasticloadbalancing.eu-west-1.amazonaws.com" };

            Console.WriteLine("Using region eu-west for all operations.\n");

            AmazonRoute53 r53 = AWSClientFactory.CreateAmazonRoute53Client();
            AmazonEC2 ec2 = AWSClientFactory.CreateAmazonEC2Client(ec2Config);
            AmazonElasticLoadBalancing elb = AWSClientFactory.CreateAmazonElasticLoadBalancingClient(elbConfig);

            // Listamos todos los RecordSets de tipo "CNAME", listamos todas nuestras instancias en funcionamiento,
            // generamos la lista de cambios comparando con el PublicDNS de las instancias y aplicamos los cambios
            var recordSets = ListRecordSets(r53);
            var runningInstances = ListRunningInstances(ec2);
            var changeList = GenerateChangeList(ec2, recordSets, runningInstances);

            ApplyResourceRecordSetsChanges(changeList);

            // Verificamos contra el DNS. Este metodo no retorna hasta que todos los cambios son visibles en el DNS desde nuestra maquina. 
            // Internamente Volvera a pedir toda la lista de ResourceRecordSets con los cambios ya aplicados.
            VerifyChanges(ec2, r53, runningInstances);

            ConfigureLoadBalancer(elb, runningInstances);

            Console.WriteLine("\nDone.");
            Console.ReadKey();
        }


        static private string GetHostedZoneIDUnusualSoccer(AmazonRoute53 r53)
        {
            /*
            GetHostedZoneRequest r53Request = new GetHostedZoneRequest();
            r53Request.Id = "ZHCBCSDXFPZMH";

            GetHostedZoneResponse r53Response = r53.GetHostedZone(r53Request);
            var test = r53Response.GetHostedZoneResult.HostedZone;
            */

            return "ZHCBCSDXFPZMH";
        }


        static private IEnumerable<ResourceRecordSet> ListRecordSets(AmazonRoute53 r53)
        {
            Console.WriteLine("Listing ResourceRecordSets...\n");

            IEnumerable<ResourceRecordSet> ret = new List<ResourceRecordSet>();

            try
            {
                ListResourceRecordSetsRequest listRequest = new ListResourceRecordSetsRequest();
                listRequest.HostedZoneId = GetHostedZoneIDUnusualSoccer(r53);

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

        static private List<RunningInstance> ListRunningInstances(AmazonEC2 ec2)
        {
            List<RunningInstance> runningInstances = new List<RunningInstance>();
            List<string> pendingInstancesIDs = new List<string>();

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

                    if (instanceName != null)
                    {
                        if (instance.InstanceState.Name == "pending")
                        {
                            Console.WriteLine("Instance {0} is PENDING. We will wait until ready.", instanceName);
                            pendingInstancesIDs.Add(instance.InstanceId);
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
                        Console.WriteLine("Instance {0} has no entry in the record set (TODO: create entries) ", instanceName);
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

        static private ResourceRecordSet GetResourceRecordSetForInstanceName(string instanceName, IEnumerable<ResourceRecordSet> resourceRecordSets)
        {
            return resourceRecordSets.SingleOrDefault(rrs => rrs.Name.StartsWith(instanceName.ToLower()));
        }

        static private void AddChangesForInstance(RunningInstance instance, ResourceRecordSet rss, List<Change> changes)
        {
            var change = new Change();
            change.Action = "DELETE";
            change.ResourceRecordSet = rss;
            changes.Add(change);

            var modified = CloneRecordSet(rss);
            modified.ResourceRecords = new List<ResourceRecord>() { new ResourceRecord() { Value = instance.PublicDnsName } };

            change = new Change();
            change.Action = "CREATE";
            change.ResourceRecordSet = modified;
            changes.Add(change);
        }

        static private void ApplyResourceRecordSetsChanges(List<Change> changes)
        {
            if (changes.Count > 0)
            {
                AmazonRoute53 r53 = AWSClientFactory.CreateAmazonRoute53Client();

                ChangeResourceRecordSetsRequest changeRequest = new ChangeResourceRecordSetsRequest();
                changeRequest.HostedZoneId = GetHostedZoneIDUnusualSoccer(r53);
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

        static private void VerifyChanges(AmazonEC2 ec2, AmazonRoute53 r53, IEnumerable<RunningInstance> runningInstances)
        {
            Console.WriteLine("\n\nVerifying that changes are visible from our computer by querying the DNS:\n");

            // We list the ResourceRecorSets again, after being INSYNC...
            IEnumerable<ResourceRecordSet> resourceRecordSets = ListRecordSets(r53);

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
            Console.WriteLine("\nConfiguring the Load Balancer...\n");

            var request = new DescribeLoadBalancersRequest() { LoadBalancerNames = new List<string>() { "TheBalancer" } };

            // Sacamos todas las instancias que esten out of service
            var healthResponse = elb.DescribeInstanceHealth(new DescribeInstanceHealthRequest() { LoadBalancerName = "TheBalancer" });
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
                    LoadBalancerName = "TheBalancer"
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
                    LoadBalancerName = "TheBalancer"
                });
            }

            // Y ahora vamos a esperar a que estan nuevas instancias esten en servicio
            bool bAllReady = false;

            do
            {
                Console.WriteLine("Waiting for all instances to be InService...");

                healthResponse = elb.DescribeInstanceHealth(new DescribeInstanceHealthRequest() { LoadBalancerName = "TheBalancer" });
                bAllReady = healthResponse.DescribeInstanceHealthResult.InstanceStates.All(inst => inst.State == "InService");

                if (!bAllReady)
                    System.Threading.Thread.Sleep(10000);

            } while (!bAllReady);
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
        
    }
}

/*
  // Print the number of Amazon SimpleDB domains.
                AmazonSimpleDB sdb = AWSClientFactory.CreateAmazonSimpleDBClient();
                ListDomainsRequest sdbRequest = new ListDomainsRequest();

                try
                {
                    ListDomainsResponse sdbResponse = sdb.ListDomains(sdbRequest);

                    if (sdbResponse.IsSetListDomainsResult())
                    {
                        int numDomains = 0;
                        numDomains = sdbResponse.ListDomainsResult.DomainName.Count;
                        sr.WriteLine("You have " + numDomains + " Amazon SimpleDB domain(s) in the US-East (Northern Virginia) region.");
                    }
                }
                catch (AmazonSimpleDBException ex)
                {
                    if (ex.ErrorCode != null && ex.ErrorCode.Equals("AuthFailure"))
                    {
                        sr.WriteLine("The account you are using is not signed up for Amazon SimpleDB.");
                        sr.WriteLine("You can sign up for Amazon SimpleDB at http://aws.amazon.com/simpledb");
                    }
                    else
                    {
                        sr.WriteLine("Caught Exception: " + ex.Message);
                        sr.WriteLine("Response Status Code: " + ex.StatusCode);
                        sr.WriteLine("Error Code: " + ex.ErrorCode);
                        sr.WriteLine("Error Type: " + ex.ErrorType);
                        sr.WriteLine("Request ID: " + ex.RequestId);
                        sr.WriteLine("XML: " + ex.XML);
                    }
                }
                sr.WriteLine();

                // Print the number of Amazon S3 Buckets.
                AmazonS3 s3Client = AWSClientFactory.CreateAmazonS3Client();

                try
                {
                    ListBucketsResponse response = s3Client.ListBuckets();
                    int numBuckets = 0;
                    if (response.Buckets != null &&
                        response.Buckets.Count > 0)
                    {
                        numBuckets = response.Buckets.Count;
                    }
                    sr.WriteLine("You have " + numBuckets + " Amazon S3 bucket(s) in the US Standard region.");
                }
                catch (AmazonS3Exception ex)
                {
                    if (ex.ErrorCode != null && (ex.ErrorCode.Equals("InvalidAccessKeyId") ||
                        ex.ErrorCode.Equals("InvalidSecurity")))
                    {
                        sr.WriteLine("Please check the provided AWS Credentials.");
                        sr.WriteLine("If you haven't signed up for Amazon S3, please visit http://aws.amazon.com/s3");
                    }
                    else
                    {
                        sr.WriteLine("Caught Exception: " + ex.Message);
                        sr.WriteLine("Response Status Code: " + ex.StatusCode);
                        sr.WriteLine("Error Code: " + ex.ErrorCode);
                        sr.WriteLine("Request ID: " + ex.RequestId);
                        sr.WriteLine("XML: " + ex.XML);
                    }
                }
                sr.WriteLine("Press any key to continue...");
            }
            return sb.ToString();
*/