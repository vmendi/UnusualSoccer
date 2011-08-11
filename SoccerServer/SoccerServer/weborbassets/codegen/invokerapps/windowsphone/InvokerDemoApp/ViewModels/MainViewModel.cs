using System;
using System.ComponentModel;
using System.Collections.Generic;
using System.Diagnostics;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Collections.ObjectModel;
using System.Reflection;
using Weborb.Client;

namespace Invoker
{
  public class MainViewModel : INotifyPropertyChanged
  {
    private Dictionary<MethodInfo, Dictionary<String, ArgInfo>> methods = new Dictionary<MethodInfo, Dictionary<String, ArgInfo>>();
    private MethodInfo _selectedMethod;
    public MethodInfo SelectedMethod 
    {
      get
      {
        return _selectedMethod;
      }

      set
      {
        if( value != _selectedMethod )
        {
          _selectedMethod = value;
          NotifyPropertyChanged( "SelectedMethod" );
          NotifyPropertyChanged( "CurrentMethodName" );
          NotifyPropertyChanged( "CurrentMethodReturnType" );
        }
      }
    }

    public DetailsPage DetailsView { get; set; }

    public MainViewModel()
    {
      this.Items = new ObservableCollection<ItemViewModel>();
    }

    /// <summary>
    /// A collection for ItemViewModel objects.
    /// </summary>
    public ObservableCollection<ItemViewModel> Items { get; private set; }

    public bool IsDataLoaded
    {
      get;
      private set;
    }

    public String AppTitle
    {
      get
      {
        return ServiceLibInfo.CLASS_NAME;
      }
    }

    public String WebORBURL
    {
      get
      {
        return ServiceLibInfo.WEBORB_URL;
      }

      set
      {
        ServiceLibInfo.WEBORB_URL = value;
      }
    }

    /// <summary>
    /// Creates and adds a few ItemViewModel objects into the Items collection.
    /// </summary>
    public void LoadData()
    {
      MethodInfo[] Methodinfo = GetMethodsWithType( ServiceLibInfo.CLASS_NAME );

      foreach( MethodInfo method in Methodinfo )
      {
        try
        {
          AddToModel(method);
        }
        catch (Exception)
        {
          continue;
        }
        ItemViewModel item = new ItemViewModel();
        item.MethodName = method.Name;
        item.Method = method;
        item.Signature = StringifyMethodName( method );
        this.Items.Add( item );
      }
      this.IsDataLoaded = true;
    }

    public event PropertyChangedEventHandler PropertyChanged;
    private void NotifyPropertyChanged( String propertyName )
    {
      PropertyChangedEventHandler handler = PropertyChanged;
      if( null != handler )
      {
        handler( this, new PropertyChangedEventArgs( propertyName ) );
      }
    }

    public string StringifyMethodName( MethodInfo MethodInfo )
    {
      string methodSignature = string.Empty;
      ParameterInfo[] parms = MethodInfo.GetParameters();

      for( int i = 0; i < parms.Length - 1; i++ )
      {
        methodSignature += parms[ i ].ParameterType.Name;
        methodSignature += " ";
        methodSignature += parms[ i ].Name;

        if( i != parms.Length - 2 )
          methodSignature += ", ";
      }

      return MethodInfo.Name + "(" + methodSignature + ")";
    }

    public MethodInfo[] GetMethodsWithType( string ClassName )
    {
      Type MyType = Type.GetType( ClassName );

      if( MyType == null )
        MyType = ServiceLibInfo.testAssembly.GetType( ClassName );

      MethodInfo[] methodInfos = MyType.GetMethods( BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.Instance );
      List<MethodInfo> methods = new List<MethodInfo>();

      foreach( MethodInfo method in methodInfos )
      {
        ParameterInfo[] paramInfo = method.GetParameters();

        if( paramInfo.Length > 0 )
        {
          Type responderArg = paramInfo[ paramInfo.Length - 1 ].ParameterType;
          Type genericResponder = typeof( Responder<> );

          if( responderArg.IsGenericType && responderArg.GetGenericTypeDefinition().Equals( genericResponder ) )
            methods.Add( method );
        }
      }

      return methods.ToArray();
    }

    public void AddToModel(MethodInfo method)
    {
      ParameterInfo[] args = method.GetParameters();
      Dictionary<String, ArgInfo> argInfos = new Dictionary<String, ArgInfo>(args.Length);

      for (int i = 0; i < args.Length - 1; i++)
        argInfos["arg" + i] = CreateArgInfo(args[i].ParameterType);

      methods.Add(method, argInfos);
    }

    internal ArgInfo CreateArgInfo( Type type )
    {
      ArgInfo argInfo;

      if( type.IsArray )
      {
        ArrayInfo arrayInfo = new ArrayInfo();
        arrayInfo.ArrayElementType = type.HasElementType ? type.GetElementType() : typeof( Object );
        argInfo = arrayInfo;
      }
      else if( type.IsGenericType )
      {
        if (!GenericInfo.IsSupported(type))
          throw new Exception("Not supported");
        GenericInfo genericInfo = new GenericInfo();
        genericInfo.ArrayElementType = type.GetGenericArguments()[ 0 ];
        argInfo = genericInfo;
      }
      else if (type.IsPrimitive || type == typeof(String) || type == (typeof(StringBuilder)) || type == typeof(DateTime) || type == typeof(Object))
      {
        argInfo = new PrimitiveInfo();
      }
      else
      {
        argInfo = new ComplexTypeInfo();
      }

      argInfo.Model = this;
      argInfo.Type = type;
      return argInfo;
    }

    public void ClearMethodModel()
    {
      foreach( ArgInfo argInfo in CurrentMethodArgInfo.Values )
        argInfo.Cleanup();
    }

    internal Dictionary<String, ArgInfo> CurrentMethodArgInfo
    {
      get
      {
        return methods[ SelectedMethod ];
      }
    }

    public String CurrentMethodReturnType
    {
      get
      {
        return SelectedMethod.ReturnType.GetGenericArguments()[ 0 ].Name;
      }
    }

    public String CurrentMethodName
    {
      get
      {
        if( SelectedMethod != null )
          return SelectedMethod.Name;
        else
          return "";
      }
    }

    public String ErrorText
    {
      get;
      set;
    }

    public Object Result
    {
      get;
      set;
    }

    public void AddArrayItem( object sender, RoutedEventArgs e )
    {
      HyperlinkButton hyperlink = (HyperlinkButton) sender;
      ArrayInfo model = (ArrayInfo) hyperlink.Tag;
      model.AddChildRow();
      RenderRequestGrid();
    }

    public static void ExpandItem(object sender, RoutedEventArgs e)
    {
      HyperlinkButton hyperlink = (HyperlinkButton)sender;
      ComplexTypeInfo model = (ComplexTypeInfo)hyperlink.Tag;
      model.Expand();
      model.Model.RenderRequestGrid();
    }

    public static void CollapseItem(object sender, RoutedEventArgs e)
    {
      HyperlinkButton hyperlink = (HyperlinkButton)sender;
      ComplexTypeInfo model = (ComplexTypeInfo)hyperlink.Tag;
      model.Collapse();
      model.Model.RenderRequestGrid();
    }

    public void RenderRequestGrid()
    {
      int row = 1;
      ViewHelper.ClearGrid( DetailsView.RequestMethodGrid );
      List<UIElement> cells = new List<UIElement>();

      foreach( KeyValuePair<String, ArgInfo> arg in CurrentMethodArgInfo )
      {
        cells.AddRange( arg.Value.RenderRow( arg.Key, ref row, 0 ) );
        row++;
      }

      for( int i = 0; i < row - 1; i++ )
      {
        RowDefinition rowDef = new RowDefinition();
        rowDef.Height = new GridLength( 50 );
        DetailsView.RequestMethodGrid.RowDefinitions.Add( rowDef );
      }

      foreach( UIElement el in cells )
        DetailsView.RequestMethodGrid.Children.Add( el );
#if( !WINDOWS_PHONE )
          GenerateCode();
#endif
    }
  }
}