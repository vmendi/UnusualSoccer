using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

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
                    StartProject();
            }
        }        
    }
}