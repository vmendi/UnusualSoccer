using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Management.Automation;

namespace Commands
{
    [Cmdlet(VerbsLifecycle.Start, "Project")]
    public class StartProject : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string Project { get; set; }

        [Parameter(Position = 1, Mandatory = true)]
        public string LoadBalancerName { get; set; }

        [Parameter(Position = 2, Mandatory = true)]
        public string HostedZone { get; set; }        

        protected override void ProcessRecord()
        {
            var runningInstances = AmazonCmdlet.Core.StartProject(Project, LoadBalancerName, HostedZone);
            WriteObject(runningInstances, true);
        }
    }

    [Cmdlet(VerbsLifecycle.Wait, "AllInstancesInELB")]
    public class WaitForELB : PSCmdlet
    {
        [Parameter(Position = 0, Mandatory = true)]
        public string LoadBalancerName { get; set; }

        protected override void ProcessRecord()
        {
            AmazonCmdlet.Core.WaitAllInstancesInELB(LoadBalancerName);
        }
    }
}
