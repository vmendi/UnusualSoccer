using System;
using System.Collections;
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
using System.Windows.Navigation;
using Microsoft.Phone.Controls;
using System.Reflection;
using Weborb.Client;

namespace Invoker
{
  public partial class DetailsPage : PhoneApplicationPage
  {
    // Constructor
    public DetailsPage()
    {
      InitializeComponent();
      DataContext = App.ViewModel;
    }

    // When page is navigated to set data context to selected item in list
    protected override void OnNavigatedTo( NavigationEventArgs e )
    {
      string selectedIndex = "";
      if( NavigationContext.QueryString.TryGetValue( "selectedItem", out selectedIndex ) )
      {
        int index = int.Parse( selectedIndex );
        App.ViewModel.SelectedMethod = ( (ItemViewModel) App.ViewModel.Items[ index ] ).Method;
        App.ViewModel.DetailsView = this;
        App.ViewModel.RenderRequestGrid();
      }
    }

    private void InvokeButton_Click( object sender, RoutedEventArgs e )
    {
      try
      {
          Dictionary<String, ArgInfo> argModel = App.ViewModel.CurrentMethodArgInfo;
          List<Object> args = new List<Object>();

          foreach( ArgInfo arg in argModel.Values )
            args.Add( arg.Value );

          InvokeMethod( ServiceLibInfo.CLASS_NAME, App.ViewModel.SelectedMethod, args.ToArray() );
       // Errorlabel.Text = "";
      }
      catch( Exception err )
      {
        App.ViewModel.ErrorText = err.Message;
        NavigationService.Navigate( new Uri( "/ErrorPage.xaml", UriKind.Relative ) );
        //Errorlabel.Text = err.Message.ToString();
      }
    }

    public void InvokeMethod( string ClassName, MethodInfo methodinfo, params object[] list )
    {
      ServiceModel model = new ServiceModel( this );
      Type MyType = ServiceLibInfo.testAssembly.GetType( ClassName );
      ConstructorInfo TestClassConstructor = MyType.GetConstructor( new Type[] { typeof( UserControl ), typeof( String ) } );
      object TestClassObject = TestClassConstructor.Invoke( new object[] { this, App.ViewModel.WebORBURL } );
      ParameterInfo[] parameters = methodinfo.GetParameters();
      Type[] returnGenericArgs = parameters[ parameters.Length - 1 ].ParameterType.GetGenericArguments();
      MethodInfo handlerMethod = model.GetType().GetMethod( methodinfo.Name + "ResultHandler", returnGenericArgs );
      Type responseHandlerType = typeof( ResponseHandler<> );
      responseHandlerType = responseHandlerType.MakeGenericType( returnGenericArgs );
      Delegate d = Delegate.CreateDelegate( responseHandlerType, model, handlerMethod );

      MethodInfo errorhandlerMethod = model.GetType().GetMethod( "ErrorHandler", new Type[] { typeof( Fault ) } );
      Delegate errordel = Delegate.CreateDelegate( typeof( ErrorHandler ), model, errorhandlerMethod );

      Type responderType = typeof( Responder<> );
      responderType = responderType.MakeGenericType( returnGenericArgs );
      Object responderObj = Activator.CreateInstance( responderType, new object[] { d, errordel } );

      if( parameters.Length == 1 )
      {
        list = new object[] { responderObj };
      }
      else
      {
        object[] newlist = new object[ list.Length + 1 ];
        Array.Copy( list, newlist, list.Length );
        newlist[ newlist.Length - 1 ] = responderObj;

        list = newlist;
      }

      methodinfo.Invoke( TestClassObject, list );
    }
  }
}