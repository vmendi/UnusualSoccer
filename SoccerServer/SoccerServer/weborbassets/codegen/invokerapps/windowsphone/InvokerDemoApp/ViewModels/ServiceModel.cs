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
using System.Windows.Navigation;
using Weborb.Client;

namespace Invoker
{
  public class ServiceModel
  {
    private DetailsPage page;

    public ServiceModel( DetailsPage page )
    {
      this.page = page;
    }

    public void ErrorHandler( Fault fault )
    {
      App.ViewModel.ErrorText = fault.Message;
      page.NavigationService.Navigate( new Uri( "/ErrorPage.xaml", UriKind.Relative ) );
      //System.Windows.Browser.HtmlPage.Window.Alert( " in fault - " + fault.Message );
    }


    public void HideIdentityResultHandler( weborb.examples.Identity ReturnObj )
    {
      DisplayResult( ReturnObj );
    }


    private void DisplayResult( object result )
    {
      App.ViewModel.Result = result;
      page.NavigationService.Navigate( new Uri( "/ResultPage.xaml", UriKind.Relative ) );
    }
  }
}
