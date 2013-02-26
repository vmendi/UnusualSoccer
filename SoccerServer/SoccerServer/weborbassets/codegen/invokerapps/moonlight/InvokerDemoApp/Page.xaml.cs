using System;
using System.Text;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;

using System.Reflection;
using System.Collections;
using System.Windows.Media;
using System.Windows.Shapes;

using Weborb.Client;
using Invoker.ViewModels;

namespace Invoker
{
  public partial class Page : UserControl
  {
    private PageModel model;
    int CountRequest = 0;
    int CountResult = 0;

    public Page()
    {
      this.model = new PageModel( this );
      this.InitializeComponent();
    }

    private void UserControl_Loaded( object sender, RoutedEventArgs e )
    {
      MethodInfo[] Methodinfo = GetMethodsWithType(CLASS_NAME);

      foreach (MethodInfo method in Methodinfo)
      {
        try
        {
          model.AddToModel(method);
        }
        catch (Exception err)
        {
          continue;
        }
        ComboBoxItem item = new ComboBoxItem();
        item.Content = StringifyMethodName(method);
        item.Tag = method;
        InvokeMethodComboBox.Items.Add(item);
      }

      Errorlabel.Text = "";
    }

    public void GenerateCode()
    {
      Dictionary<String, ArgInfo> argInfos = model.CurrentMethodArgInfo;
      StringBuilder sb = new StringBuilder();
      String methodReturnType =  model.CurrentMethodReturnType;
      sb.Append( "public class MyInvoker\n" ).
         Append( "{\n" ).
         Append( "  private " ).Append( CLASS_NAME ).Append( " service;\n" ).
         Append( "  public void Invoke()\n" ).
         Append( "  {\n" ).
         Append( "    service = new " ).Append( CLASS_NAME ).Append( "();\n" ).
         Append( "    Responder<" ).Append( methodReturnType ).Append( "> myResponder = new Responder<" ).Append( methodReturnType ).Append( ">( gotResult, gotError );\n" );

      foreach( String arg in argInfos.Keys )
        sb.Append( argInfos[ arg ].ToCode( arg ) );

      sb.Append( "    service." ).Append( model.CurrentMethodName ).Append( "( " );

      foreach( String arg in argInfos.Keys )
        sb.Append( arg ).Append( ", " );

      sb.Append( "myResponder );\n" ).
        Append( "   }\n" ).
        Append( "}" );

      this.CodeSample.Text = sb.ToString();
    }

    public void RenderRequestGrid()
    {
      int row = 1;
      ClearGrid( RequestMethodGrid );
      List<UIElement> cells = new List<UIElement>();

      foreach( KeyValuePair<String, ArgInfo> arg in model.CurrentMethodArgInfo )
      {
        cells.AddRange( arg.Value.RenderRow( arg.Key, ref row, 0 ) );
        row++;
      }

      for( int i = 0; i < row-1; i++ )
      {
        RowDefinition rowDef = new RowDefinition();
        rowDef.Height = new GridLength( 25 );
        RequestMethodGrid.RowDefinitions.Add( rowDef );
      }

      foreach( UIElement el in cells )
        RequestMethodGrid.Children.Add( el );

      GenerateCode();
    }

    public void ClearGrid( Grid grid )
    {
      if( grid.RowDefinitions.Count == 1 )
        return;

      RowDefinition header = grid.RowDefinitions[ 0 ];
      int CountrolTypeCount = grid.Children.Count;

      for( int i = CountrolTypeCount - 1; i >= 3; i-- )
        grid.Children.RemoveAt( i );

      grid.RowDefinitions.Clear();
      grid.RowDefinitions.Add( header );
    }

    private void addLabelRow( Grid grid, string col0Text, string col1Text, string col2Text )
    {
      RowDefinition row = new RowDefinition();
      row.Height = new GridLength( 25 );
      grid.RowDefinitions.Add( row );
      TextBlock ArgumentLabel = setLabel( col0Text, grid.RowDefinitions.Count - 1, 0 );
      TextBlock TypeLabel = setLabel( col1Text, grid.RowDefinitions.Count - 1, 1 );
      TextBlock ValueLabel = setLabel( col2Text, grid.RowDefinitions.Count - 1, 2 );

      Border Argumentborder = setBorder( grid.RowDefinitions.Count - 1, 0 );
      Border Typeborder = setBorder( grid.RowDefinitions.Count - 1, 1 );
      Border Valueborder = setBorder( grid.RowDefinitions.Count - 1, 2 );

      grid.Children.Add( Argumentborder );
      grid.Children.Add( Typeborder );
      grid.Children.Add( Valueborder );

      grid.Children.Add( ArgumentLabel );
      grid.Children.Add( TypeLabel );
      grid.Children.Add( ValueLabel );
    }


    private static void setControl( Control control, int row, int col )
    {
      control.SetValue( Grid.ColumnProperty, col );
      control.SetValue( Grid.RowProperty, row );
    }

    public TextBlock setLabel( string text, int row, int col )
    {
      TextBlock label = new TextBlock();
      label.Text = text;
      label.Margin = new Thickness( 5, 1, 1, 1 );
      label.SetValue( Grid.ColumnProperty, col );
      label.SetValue( Grid.RowProperty, row );
      return label;
    }


    public string StringifyMethodName( MethodInfo MethodInfo )
    {
      string methodSignature = string.Empty;
      ParameterInfo[] parms = MethodInfo.GetParameters();

      for( int i = 0; i < parms.Length; i++ )
      {
        methodSignature += parms[ i ].ParameterType.Name;
        methodSignature += " ";
        methodSignature += parms[ i ].Name;

        if( i != parms.Length - 1 )
          methodSignature += ", ";
      }

      return MethodInfo.Name + "(" + methodSignature + ")";
    }

    private void InvokeMethodComboBox_SelectionChanged( object sender, SelectionChangedEventArgs e )
    {
      try
      {
        if( InvokeMethodComboBox.SelectedItem.ToString() != "" )
        {
          ComboBoxItem item = (ComboBoxItem) InvokeMethodComboBox.SelectedItem;
          MethodInfo method = (MethodInfo) item.Tag;
          model.SelectedMethod = method;
          model.ClearMethodModel();
          RenderRequestGrid();
        }

        Errorlabel.Text = "";
      }
      catch( Exception err )
      {
        System.Windows.Browser.HtmlPage.Window.Alert( err.ToString() );
        Errorlabel.Text = err.Message.ToString();
      }
    }

    void InvokeButton_Click( object sender, RoutedEventArgs e )
    {
      try
      {
        if( InvokeMethodComboBox.SelectedItem.ToString() != "" )
        {
          Dictionary<String, ArgInfo> argModel = model.CurrentMethodArgInfo;
          List<Object> args = new List<Object>();

          foreach( ArgInfo arg in argModel.Values )
            args.Add( arg.Value );

          InvokeMethod( CLASS_NAME, model.SelectedMethod, args.ToArray() );
        }

        Errorlabel.Text = "";
      }
      catch( Exception err )
      {
        System.Windows.Browser.HtmlPage.Window.Alert( err.ToString() );
        Errorlabel.Text = err.Message.ToString();
      }
    }

    public void TypeAnalyzer( Type type, int Row, Object obj, String label )
    {
      String objectType = TypeChecker( type );

      if( objectType == "Simple" || type == typeof(StringBuilder) )
        SimpleResultType( type, Row, obj, label );
      else if( objectType == "Array" )
        ArrayResultType( type, Row, obj, label );
      else if( objectType == "Complex" )
        ComplexResultType( type, Row, obj, label );
    }

    public void ComplexResultType(Type type, int Row, Object objReturnValue, string PropertyName)
    {
      RowDefinition rowOne = new RowDefinition();
      rowOne.Height = new GridLength(25);
      ResultdataGrid.RowDefinitions.Add(rowOne);
      ResultdataGrid.Children.Add(setBorder(Row, 0));
      ResultdataGrid.Children.Add(setLabel(PropertyName != string.Empty ? PropertyName : "Result", Row, 0));
      ResultdataGrid.Children.Add(setBorder(Row, 1));
      ResultdataGrid.Children.Add(setLabel(type.Name, Row, 1));
      ResultdataGrid.Children.Add(setBorder(Row, 2));

      if( objReturnValue == null )
        return;

      if( objReturnValue is IDictionary )
      {
        IDictionary dictionary = (IDictionary) objReturnValue;
        int rowCount = dictionary.Keys.Count;

        foreach( Object key in dictionary.Keys )
        {
          Object value = dictionary[ key ];
          TypeAnalyzer( value.GetType(), rowCount, value, AddSpace( key.ToString(), CountResult++ ) );
          CountResult--;
        }
      }
      else
      {
        MemberInfo[] propertyinfo = GetReadOnlyProperties( type.FullName );

        foreach( MemberInfo property in propertyinfo )
        {
          int rowCount = ResultdataGrid.RowDefinitions.Count;

          if( property != null )
          {
            PropertyInfo PropertyInfo = type.GetProperty( property.Name );
            if( PropertyInfo != null )
            {
              Object Objvalue = PropertyInfo.GetValue( objReturnValue, null );
              TypeAnalyzer( PropertyInfo.PropertyType, rowCount, Objvalue, AddSpace( property.Name, CountResult++ ) );
              CountResult--;
            }
            else
            {
              FieldInfo field = type.GetField( property.Name );
              Object Objvalue = field.GetValue( objReturnValue );
              TypeAnalyzer( field.FieldType, rowCount, Objvalue, AddSpace( property.Name, CountResult++ ) );
              CountResult--;
            }

          }
        }
      }
    }

    public void ArrayResultType( Type type, int Row, Object objReturnValue, string PropertName )
    {
      if(objReturnValue == null)
        objReturnValue = new object[0];
      RowDefinition rowOne = new RowDefinition();
      rowOne.Height = new GridLength( 25 );
      ResultdataGrid.RowDefinitions.Add( rowOne );
      ResultdataGrid.Children.Add( setBorder( Row, 0 ) );
      ResultdataGrid.Children.Add( setLabel(  PropertName != string.Empty ? PropertName : type.Name, Row, 0 ) );
      ResultdataGrid.Children.Add( setBorder( Row, 1 ) );
      ResultdataGrid.Children.Add( setLabel( "Array", Row, 1 ) );
      ResultdataGrid.Children.Add( setBorder( Row, 2 ) );
      ResultdataGrid.Children.Add( setLabel( "Size: " + ( (ICollection) objReturnValue ).Count, Row, 2 ) );

      int CountP = 0;
      foreach( object objval in (ICollection) objReturnValue )
      {
        TypeAnalyzer( objval.GetType(), ResultdataGrid.RowDefinitions.Count, objval, AddSpace( "Array Item " + ( CountP + 1 ), CountResult++ ) );
        CountResult--;
        CountP++;
      }
    }


    public Object ObjectConverter( Type DataType, Object obj )
    {
      Object convertobj = null;
      if( DataType == typeof( String ) )
      {
        String str = Convert.ToString( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Char ) )
      {
        char str = Convert.ToChar( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Int16 ) )
      {
        Int16 str = Convert.ToInt16( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Int32 ) )
      {
        Int32 str = Convert.ToInt32( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Int64 ) )
      {
        Int64 str = Convert.ToInt64( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Byte ) )
      {
        Byte str = Convert.ToByte( obj );
        convertobj = str;
      }
      else if( DataType == typeof( DateTime ) )
      {
        DateTime str = Convert.ToDateTime( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Decimal ) )
      {
        Decimal str = Convert.ToDecimal( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Double ) )
      {
        Double str = Convert.ToDouble( obj );
        convertobj = str;
      }
      else if( DataType == typeof( Boolean ) )
      {
        Boolean str = Convert.ToBoolean( obj );
        convertobj = str;
      }
      else if( DataType.IsArray )
      {

        convertobj = (Array) obj;

      }
      else
      {
        Type ComplextType = DataType;
        if( ComplextType != null )
        {
          object ObjInstance = Activator.CreateInstance( ComplextType, obj );
          convertobj = ObjInstance;
        }
        else
        {
          object ObjInstance = new Object();
          ComplextType = testAssembly.GetType( DataType.FullName );
          if( ComplextType.IsArray )
          {
            ObjInstance = Activator.CreateInstance( ComplextType, ( (Array) obj ).Length );
            ObjInstance = obj;

          }
          convertobj = ObjInstance;
        }
      }

      return convertobj;
    }
 
    public void SimpleResultType( Type returnType, int Row, object result, string content )
    {
      addLabelRow( ResultdataGrid, content, returnType.Name, result == null ? "null" : result.ToString() );
    }

    public string AddSpace( string Content, int noofSpace )
    {
      for( int count = 0; count < noofSpace; count++ )
        Content = "   " + Content;

      return Content;
    }

    public string TypeChecker( Type type )
    {
      if( type.IsPrimitive || type == typeof( String ) || type == typeof( Decimal ) || type == typeof( DateTime ) )
        return "Simple";
      else if( type.IsGenericType && type.GetGenericArguments().Length == 1 )
        return "Array";
      else if( type.IsArray )
        return "Array";
      else
        return "Complex";
    }

    public Border setBorder( int row, int col )
    {
      Border border = new Border();

      if( row != 0 && row % 2 == 0 )
        border.Background = new SolidColorBrush( Color.FromArgb( 255, 164, 194, 220 ) );
      else
        border.Background = new SolidColorBrush( Color.FromArgb( 255, 186, 214, 235 ) );

      border.BorderThickness = new Thickness( 0, 0, col == 2 ? 0 : 1, 0 );
      border.BorderBrush = new SolidColorBrush( Colors.White );
      border.SetValue( Grid.RowProperty, row );
      border.SetValue( Grid.ColumnProperty, col );
      return border;
    }

    public Border setBorderTOTextBox( int row, int col )
    {
      Border border = new Border();
      border.Background = new SolidColorBrush( Colors.White );
      border.Margin = new Thickness( 5, 0, 0, 0 );
      border.CornerRadius = new CornerRadius( 6 );
      border.HorizontalAlignment = HorizontalAlignment.Left;
      border.VerticalAlignment = VerticalAlignment.Center;
      border.Height = 20;
      border.Width = 150;
      border.OpacityMask = new SolidColorBrush( Colors.White );
      border.BorderThickness = new Thickness( 1, 1, 1, 1 );
      border.BorderBrush = new SolidColorBrush( Colors.White );
      border.SetValue( Grid.RowProperty, row );
      border.SetValue( Grid.ColumnProperty, col );
      return border;
    }

    public void hyperlink_Click( object sender, RoutedEventArgs e )
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
      model.Model.Controller.RenderRequestGrid();
    }

    public static void ItemChanged(object sender, RoutedEventArgs e)
    {
      ArgInfo model = (ArgInfo)((Control)sender).Tag;
      model.Model.Controller.GenerateCode();
    }

    public static void CollapseItem(object sender, RoutedEventArgs e)
    {
      HyperlinkButton hyperlink = (HyperlinkButton)sender;
      ComplexTypeInfo model = (ComplexTypeInfo)hyperlink.Tag;
      model.Collapse();
      model.Model.Controller.RenderRequestGrid();
    }

    public MethodInfo[] GetMethodsWithType( string ClassName )
    {
      Type MyType = Type.GetType( ClassName );

      if( MyType == null )
        MyType = testAssembly.GetType( ClassName );

      MethodInfo[] methodInfos = MyType.GetMethods( BindingFlags.DeclaredOnly | BindingFlags.Public | BindingFlags.Instance );
      List<MethodInfo> methods = new List<MethodInfo>();

      foreach( MethodInfo method in methodInfos )
      {
        ParameterInfo[] paramInfo = method.GetParameters();
        Type[] genericArgs = method.ReturnType.GetGenericArguments();

        if( genericArgs.Length == 0 )
          continue;

        Type genericResponder = typeof( Responder<> );
        genericResponder = genericResponder.MakeGenericType( genericArgs );

        if( paramInfo.Length > 0 && genericResponder.IsAssignableFrom( paramInfo[ paramInfo.Length - 1 ].ParameterType ) )
          continue;
        else
          methods.Add( method );
      }

      return methods.ToArray();
    }

    public MemberInfo[] GetReadOnlyProperties( string ClassName )
    {
      Type MyType = Type.GetType( ClassName );

      if( MyType == null )
        MyType = testAssembly.GetType( ClassName );

      MemberInfo[] members = MyType.GetMembers( BindingFlags.Instance | BindingFlags.Public );
	List<MemberInfo> membersList = new List<MemberInfo>();		
	 foreach( MemberInfo member in members )
			{
				if( member is PropertyInfo || member is FieldInfo )
					membersList.Add( member );
			}
			
      return membersList.ToArray();
    }

    public void InvokeMethod( string ClassName, MethodInfo methodinfo, params object[] list )
    {
      ServiceModel model = new ServiceModel( this );
      Type MyType = testAssembly.GetType( ClassName );// Code Edit Object Refrence Set Null  28-1-2010
      ConstructorInfo TestClassConstructor = MyType.GetConstructor( new Type[] { typeof( UserControl ), typeof( String ) } );
      object TestClassObject = TestClassConstructor.Invoke(new object[] { this, null });
      ParameterInfo[] parameter = methodinfo.GetParameters();

      Type[] returnGenericArgs = methodinfo.ReturnType.GetGenericArguments();
      MethodInfo handlerMethod = model.GetType().GetMethod( methodinfo.Name + "ResultHandler", returnGenericArgs );
      Type responseHandlerType = typeof( ResponseHandler<> );
      responseHandlerType = responseHandlerType.MakeGenericType( returnGenericArgs );
      Delegate d = Delegate.CreateDelegate( responseHandlerType, model, handlerMethod );

      MethodInfo errorhandlerMethod = model.GetType().GetMethod( "ErrorHandler", new Type[] { typeof( Fault ) } );
      Delegate errordel = Delegate.CreateDelegate( typeof( ErrorHandler ), model, errorhandlerMethod );

      Type[] argTypes = new Type[ parameter.Length + 1 ];

      for( int i = 0; i < parameter.Length; i++ )
        argTypes[ i ] = parameter[ i ].ParameterType;

      Type responderType = typeof( Responder<> );
      responderType = responderType.MakeGenericType( returnGenericArgs );
      argTypes[ argTypes.Length - 1 ] = responderType;
      methodinfo = MyType.GetMethod( methodinfo.Name, argTypes );
      Object responderObj = Activator.CreateInstance( responderType, new object[] { d, errordel } );

      if( parameter.Length == 0 )
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