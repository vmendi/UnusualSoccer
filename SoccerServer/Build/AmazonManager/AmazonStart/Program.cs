using System;
using CmdLine;

namespace AmazonStart
{
    [CommandLineArguments(Program = "AmazonStart", Title = "AWS project starter", Description = "It helps good people to start aws projects")]
    class Options
    {
        [CommandLineParameter(Name="project", ParameterIndex=1, Required=false, Description="Project name as set in AWS tag", Default="UnusualSoccer")]
        public string Project { get; set; }

        [CommandLineParameter(Name="loadbalancername", ParameterIndex=2, Required=false, Description="Load balancer name as assigned in AWS", Default="TheBalancer")] 
        public string LoadBalancerName { get; set; }

        [CommandLineParameter(Name = "hostedzone", ParameterIndex = 3, Required = false, Description = "Hosted zone Name", Default = "unusualsoccer.com")]
        public string HostedZone { get; set; }

        [CommandLineParameter(Command = "W", Required = false, Description = "Wait for all instances to be InService", Default = false)]
        public bool WaitForELB { get; set; }
    }

    class Program
    {       
        static public void Main(string[] args)
        {
            try
            {
                var options = CommandLine.Parse<Options>();

                if (options.WaitForELB)
                    AmazonCmdlet.Core.WaitAllInstancesInELB(options.LoadBalancerName);
                else
                    AmazonCmdlet.Core.StartProject(options.Project, options.LoadBalancerName, options.HostedZone);

            }
            catch (CommandLineException exception)
            {
                Console.WriteLine(exception.ArgumentHelp.Message);
                Console.WriteLine(exception.ArgumentHelp.GetHelpText(Console.BufferWidth));
            }
        }        
    }
}