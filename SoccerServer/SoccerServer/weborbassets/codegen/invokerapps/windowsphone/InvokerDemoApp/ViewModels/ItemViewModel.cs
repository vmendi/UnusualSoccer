using System;
using System.ComponentModel;
using System.Diagnostics;
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
  public class ItemViewModel : INotifyPropertyChanged
  {
    private string _methodName;
    /// <summary>
    /// Sample ViewModel property; this property is used in the view to display its value using a Binding.
    /// </summary>
    /// <returns></returns>
    public string MethodName
    {
      get
      {
        return _methodName;
      }
      set
      {
        if( value != _methodName )
        {
          _methodName = value;
          NotifyPropertyChanged( "MethodName" );
        }
      }
    }

    private string _signature;
    /// <summary>
    /// Sample ViewModel property; this property is used in the view to display its value using a Binding.
    /// </summary>
    /// <returns></returns>
    public string Signature
    {
      get
      {
        return _signature;
      }
      set
      {
        if( value != _signature )
        {
          _signature = value;
          NotifyPropertyChanged( "Signature" );
        }
      }
    }

    public MethodInfo Method { get; set; }

    public event PropertyChangedEventHandler PropertyChanged;
    private void NotifyPropertyChanged( String propertyName )
    {
      PropertyChangedEventHandler handler = PropertyChanged;
      if( null != handler )
      {
        handler( this, new PropertyChangedEventArgs( propertyName ) );
      }
    }
  }
}