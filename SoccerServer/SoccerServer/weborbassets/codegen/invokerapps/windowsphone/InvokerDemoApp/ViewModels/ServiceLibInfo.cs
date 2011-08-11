using System;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using System.Reflection;

namespace Invoker
{
  public class ServiceLibInfo
  {
    internal const string CLASS_NAME = "weborb.examples.IdentityServiceService";
    internal static Assembly testAssembly = Assembly.Load( "WindowsPhoneClassLibrary1, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" );
    internal static String WEBORB_URL = "http://localhost:8080/weborb.wo";
  }
}
