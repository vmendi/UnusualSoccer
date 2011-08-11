using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using Microsoft.Phone.Controls;

namespace Invoker
{
  public partial class WebORBURLPage : PhoneApplicationPage
  {
    public WebORBURLPage()
    {
      InitializeComponent();
      DataContext = App.ViewModel;
    }

    private void TestConnection_Click( object sender, RoutedEventArgs e )
    {
      try
      {
        HttpWebRequest request = WebRequest.CreateHttp( weborburlTextbox.Text );
        request.BeginGetResponse( new AsyncCallback( HandleURLCheck ), request );
      }
      catch( Exception exception )
      {
        App.ViewModel.ErrorText = exception.Message;
        Deployment.Current.Dispatcher.BeginInvoke(new Action(() =>
            {
                NavigationService.Navigate( new Uri( "/ErrorPage.xaml", UriKind.Relative ) );
            }));
      }
    }

    private void HandleURLCheck( IAsyncResult asyncResult )
    {
      try
      {
        HttpWebRequest httpRequest = (HttpWebRequest) asyncResult.AsyncState;
        HttpWebResponse response = (HttpWebResponse) httpRequest.EndGetResponse( asyncResult );

        Deployment.Current.Dispatcher.BeginInvoke( new Action( () =>
        {
          MessageBox.Show( "WebORB URL is valid", "Success", MessageBoxButton.OK );
        } ) );
      }
      catch( Exception exception )
      {
        App.ViewModel.ErrorText = exception.Message;
        Deployment.Current.Dispatcher.BeginInvoke( new Action( () =>
        {
          NavigationService.Navigate( new Uri( "/ErrorPage.xaml", UriKind.Relative ) );
        } ) );
      }
    }

    private void AcceptNewWebOrbURL_Click( object sender, RoutedEventArgs e )
    {
      App.ViewModel.WebORBURL = weborburlTextbox.Text;
      NavigationService.GoBack();
    }
  }
}