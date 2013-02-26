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
using System.Reflection;
using Microsoft.Phone.Controls;
using System.Text;

namespace Invoker
{
  public partial class ResultPage : PhoneApplicationPage
  {
    public ResultPage()
    {
      InitializeComponent();
      DataContext = App.ViewModel;
    }

    protected override void OnNavigatedTo( System.Windows.Navigation.NavigationEventArgs e )
    {
      Type returnType = App.ViewModel.Result == null ? typeof(Nullable) : App.ViewModel.Result.GetType();
      ViewHelper.ClearGrid( ResultdataGrid );
      TypeAnalyzer( returnType, App.ViewModel.Result, "Result" );
      base.OnNavigatedTo( e );
    }

    public void TypeAnalyzer( Type type, Object obj, String label )
    {
      if( type.IsPrimitive || type == typeof( String ) || type == typeof( Decimal ) || type == typeof( DateTime ) || type == typeof( StringBuilder ) )
        AddRow( label, type.Name, obj.ToString() );
      else if( ( type.IsGenericType && type.GetGenericArguments().Length == 1 ) || type.IsArray )
        ArrayResultType( type, obj, label );
      else if( type.IsGenericType && type.GetGenericArguments().Length == 2 )
        DictionaryResultType( type, obj, label );
      else
        ComplexResultType( type, obj, label );
    }

    private void AddRow( String argName, String type, String value )
    {
      RowDefinition row = new RowDefinition();
      row.Height = new GridLength( 50 );
      ResultdataGrid.RowDefinitions.Add( row );

      ResultdataGrid.Children.Add( ViewHelper.setBorder( ResultdataGrid.RowDefinitions.Count - 1, 0 ) );
      ResultdataGrid.Children.Add( ViewHelper.setBorder( ResultdataGrid.RowDefinitions.Count - 1, 1 ) );
      ResultdataGrid.Children.Add( ViewHelper.setBorder( ResultdataGrid.RowDefinitions.Count - 1, 2 ) );

      ResultdataGrid.Children.Add( ViewHelper.setLabel( argName, ResultdataGrid.RowDefinitions.Count - 1, 0 ) );
      ResultdataGrid.Children.Add( ViewHelper.setLabel( type, ResultdataGrid.RowDefinitions.Count - 1, 1 ) );

      if( value != null )
        ResultdataGrid.Children.Add( ViewHelper.setLabel( value, ResultdataGrid.RowDefinitions.Count - 1, 2 ) );
    }

    public void DictionaryResultType( Type type, Object obj, string PropertyName )
    {
      Type genDef = type.GetGenericTypeDefinition();

      if( typeof( KeyValuePair<,> ).IsAssignableFrom( genDef ) )
      {
        Type[] genArgs = type.GetGenericArguments();
        Object key = type.GetProperty( "Key" ).GetValue( obj, null );
        Object value = type.GetProperty( "Value" ).GetValue( obj, null );
        TypeAnalyzer( genArgs[ 1 ], value, key.ToString() );
        return;
      }
      else if( typeof( IDictionary ).IsAssignableFrom( type ) )
      {
        AddRow( PropertyName, "Object", null );

        foreach( DictionaryEntry entry in (IDictionary) obj )
          TypeAnalyzer( entry.Value.GetType(), entry.Value, entry.Key.ToString() );
      }
    }

    public void ComplexResultType( Type type, Object objReturnValue, string PropertyName )
    {
      AddRow( PropertyName != string.Empty ? PropertyName : "Result", type.Name, null );
      object ObjInstance = objReturnValue;
      if (ObjInstance == null) 
        return;
      MemberInfo[] propertyinfo = GetMembers( type );

      foreach( MemberInfo property in propertyinfo )
      {
        if( property != null )
        {
          PropertyInfo PropertyInfo = type.GetProperty( property.Name );

          if( PropertyInfo != null )
          {
            Object Objvalue = PropertyInfo.GetValue( ObjInstance, null );
            TypeAnalyzer( PropertyInfo.PropertyType, Objvalue, property.Name );
          }
          else
          {
            FieldInfo field = type.GetField( property.Name );
            Object Objvalue = field.GetValue( ObjInstance );
            TypeAnalyzer( field.FieldType,  Objvalue, field.Name );
          }
        }
      }
    }

    public void ArrayResultType( Type type, Object objReturnValue, string PropertName )
    {
      AddRow( PropertName != string.Empty ? PropertName : type.Name, "Array", "Size: " + ( (ICollection) objReturnValue ).Count );

      int CountP = 0;
      foreach( object objval in (ICollection) objReturnValue )
      {
        TypeAnalyzer( objval.GetType(), objval, "Array Item " + ( CountP + 1 ) );
        CountP++;
      }
    }

    public MemberInfo[] GetMembers( Type type )
    {
      MemberInfo[] members = type.GetMembers( BindingFlags.Instance | BindingFlags.Public );
      List<MemberInfo> membersList = new List<MemberInfo>();

      foreach( MemberInfo member in members )
        if( member is PropertyInfo || member is FieldInfo )
          membersList.Add( member );

      return membersList.ToArray();
    }
  }
}