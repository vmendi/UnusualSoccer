using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Amazon.EC2;
using Amazon.Route53;
using Amazon.S3;

namespace AmazonCmdlet
{
    internal class ExceptionPrint
    {
        static public void PrintEC2Exception(AmazonEC2Exception ex)
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

        static public void PrintR53Exception(AmazonRoute53Exception ex)
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

        static public void PrintS3Exception(AmazonS3Exception ex)
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
