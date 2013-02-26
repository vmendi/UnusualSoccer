using System;
using System.Collections.Generic;
using System.IO;
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
using WindowsPhoneMessagingChat;

namespace Invoker
{
  public partial class WebORBURLPage : PhoneApplicationPage
  {
    public delegate void WeborbURLChanged(string url);
    public static event WeborbURLChanged WeborbURLChangedEvent;

    private volatile bool _accepted;

    public WebORBURLPage()
    {
      InitializeComponent();
      weborburlTextbox.DataContext = MainPage.WeborbUrl;
    }

    private void TestConnection_Click( object sender, RoutedEventArgs e )
    {
      TestConnection();
    }

    private void TestConnection()
    {
      EnabledUi(false);
      try
      {
        var url = weborburlTextbox.Text;
        var contentType = "application/x-amf";

        if ( url.StartsWith( "rtmpt" ) )
        {
          contentType = "application/x-fcs";
          url = GetUrl(url, "rtmpt://");
        }
        else
        {
          url = url.Replace("weborb.aspx", "weborb.aspx?diag");
        }

        HttpWebRequest request = (HttpWebRequest)WebRequest.Create(url);
        request.Method = "POST";
        request.ContentType = contentType;
        request.AllowAutoRedirect = false;
        request.BeginGetRequestStream(new AsyncCallback(HandleURLCheck), request);
      }
      catch( Exception exception )
      {
        Deployment.Current.Dispatcher.BeginInvoke(new Action(() => MessageBox.Show(exception.Message, "Error", MessageBoxButton.OK)));
        EnabledUi( true );
      }
    }

    private string GetUrl(string gateway, string protocol)
    {
      string url = gateway.Substring(protocol.Length, gateway.Length - (protocol.Length));
      var host = "";
      var port = 80;

      int hostSeparatorPos = url.IndexOf("/");
      if (hostSeparatorPos != -1)
      {
        host = url.Substring(0, hostSeparatorPos);
      }

      int portSeparatorPos = host.IndexOf(":");
      if (portSeparatorPos != -1)
      {
        port = int.Parse(host.Substring(portSeparatorPos + 1, host.Length - portSeparatorPos - 1));
        host = host.Substring(0, portSeparatorPos);
      }

      return String.Format("http://{0}:{1}/open/1", host, port);
    }

    private void HandleURLCheck( IAsyncResult asyncResult )
    {
      try
      {
        var bytesToSend = new byte[] { 0 };
        HttpWebRequest httpRequest = (HttpWebRequest)asyncResult.AsyncState;
        Stream postDataWriter = httpRequest.EndGetRequestStream(asyncResult);
        postDataWriter.Write(bytesToSend, 0, bytesToSend.Length);
        postDataWriter.Flush();
        postDataWriter.Close();

        httpRequest.BeginGetResponse(RequestResponseHandler, httpRequest);
      }
      catch( Exception exception )
      {
        Deployment.Current.Dispatcher.BeginInvoke(new Action(() => MessageBox.Show(exception.Message, "Error", MessageBoxButton.OK)));
      }
    }

    private void RequestResponseHandler( IAsyncResult asyncResult )
    {
      try
      {
        HttpWebRequest httpRequest = (HttpWebRequest) asyncResult.AsyncState;
        HttpWebResponse response = (HttpWebResponse) httpRequest.EndGetResponse(asyncResult);
        if (response.StatusCode != HttpStatusCode.OK)
          throw new Exception("Invalid URL");
        if ( _accepted )
        {
          _accepted = false;
          Dispatcher.BeginInvoke(() =>
                                   {
                                     MainPage.WeborbUrl = weborburlTextbox.Text;
                                     if(WeborbURLChangedEvent != null)
                                       WeborbURLChangedEvent( MainPage.WeborbUrl );
                                     NavigationService.Navigate( new Uri( "/MainPage.xaml", UriKind.Relative ) );
                                     
                                   });
        }
        else
        {
          Deployment.Current.Dispatcher.BeginInvoke(
            new Action(() => MessageBox.Show("WebORB URL is valid", "Success", MessageBoxButton.OK)));
        }
      }
      catch (Exception exception)
      {
        Deployment.Current.Dispatcher.BeginInvoke(new Action(() => MessageBox.Show(exception.Message, "Error", MessageBoxButton.OK)));
      }
      finally
      {
        Dispatcher.BeginInvoke(() => EnabledUi(true));
      }
    }
    
    private void EnabledUi(bool enabled)
    {
      weborburlTextbox.IsEnabled = enabled;
      AcceptButton.IsEnabled = enabled;
      TestConnectionButton.IsEnabled = enabled;
    }

    private void AcceptNewWebOrbURL_Click( object sender, RoutedEventArgs e )
    {
      _accepted = true;
      TestConnection();
    }
  }
}