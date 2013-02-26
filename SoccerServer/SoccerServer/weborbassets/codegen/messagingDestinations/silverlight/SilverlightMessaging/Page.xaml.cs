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

using Weborb.Client;
using Weborb.Types;
using Weborb.V3Types;

namespace SilverlightMessaging
{
  public partial class Page : UserControl
  {
    public Page()
    {
      InitializeComponent();
      Init();
    }

    private WeborbClient _client;


    private void Init()
    {
      _client = new WeborbClient("rtmp://localhost:4530/root", "DemoDestination");
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
      asyncMessage.headers = new Dictionary<object, object> { { "WebORBClientId", ClientId.Text } };
      asyncMessage.body = Message.Text;
      _client.Publish( asyncMessage );
    }

  }
}
