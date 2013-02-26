using System;
using System.Collections.Generic;
using System.Windows;
using Microsoft.Phone.Controls;
using Weborb.Client;
using Weborb.Types;
using Weborb.V3Types;

namespace WindowsPhoneMessagingChat
{
  public partial class MainPage : PhoneApplicationPage
  {
    private WeborbClient _client;
    
    public MainPage()
    {
      InitializeComponent();
      Init();
    }

    private void Init()
    {
      _client = new WeborbClient( App.WeborbUrl, "DemoDestination" );
      _client.Subscribed += () => Dispatcher.BeginInvoke(() => SendButton.IsEnabled = true);
      _client.Subscribe(
        new SubscribeResponder(
          message => Dispatcher.BeginInvoke(() =>
                                              {
                                                IAdaptingType[] body = message.GetBody();
                                                object mess = body[0].defaultAdapt();
                                                string sender = message.headers["WebORBClientId"].ToString() == ""
                                                                  ? "Anonymous"
                                                                  : message.headers["WebORBClientId"].ToString();
                                                Messages.Text += sender + ": " + mess + "\n";
                                              }),
          fault => Dispatcher.BeginInvoke(() => Messages.Text += fault.Message + "\n")));
    }

    private void SendButton_Click( object sender, RoutedEventArgs e )
    {
      AsyncMessage asyncMessage = new AsyncMessage();
      asyncMessage.headers = new Dictionary<object, object> {{"WebORBClientId", ClientId.Text}};
      asyncMessage.body = Message.Text;
      _client.Publish(asyncMessage);
    }

    private void ApplicationBarMenuItem_Click( object sender, EventArgs e )
    {
      NavigationService.Navigate( new Uri( "/WebORBURLPage.xaml", UriKind.Relative ) );
    }
  }
}