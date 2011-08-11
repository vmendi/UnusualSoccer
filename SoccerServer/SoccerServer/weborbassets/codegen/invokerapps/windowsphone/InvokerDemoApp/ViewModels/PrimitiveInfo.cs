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
using System.Collections.Generic;
using System.Text;

namespace Invoker
{
  internal class PrimitiveInfo : ArgInfo
  {
    public Control Control { get; set; }

    public override List<UIElement> RenderRow( String name, ref int row, int padding )
    {
      List<UIElement> basicRow = new List<UIElement>();

      basicRow.Add( ViewHelper.setBorder( row, 0 ) );
      basicRow.Add( ViewHelper.setLabel( new String( ' ', padding * 2 ) + name, row, 0 ) );
      basicRow.Add( ViewHelper.setBorder( row, 1 ) );
      basicRow.Add( ViewHelper.setLabel( TypeName, row, 1 ) );

      Control control = GetControl();
      control.SetValue( Grid.ColumnProperty, 2 );
      control.SetValue( Grid.RowProperty, row );
      basicRow.Add( ViewHelper.setBorder( row, 2 ) );

      //if( control.GetType() == typeof( TextBox ) )
      //{
      //  Border textBoxBorder = ViewHelper.setBorderTOTextBox( row, 2 );
      //  textBoxBorder.Tag = "Not Editable";
      //  basicRow.Add( textBoxBorder );
     // }

      basicRow.Add( control );
      return basicRow;
    }

    public override Object Value
    {
      get
      {
        if( Control is TextBox )
        {
          String val = ( (TextBox) Control ).Text;

          if( Type == typeof( String ) )
            return Convert.ToString( val );
          else if( Type == typeof( Char ) )
            return Convert.ToChar( val );
          else if (Type == typeof(Int16))
          {
            if (val == "")
              val = "0";
            return Convert.ToInt16(val);
          }
          else if (Type == typeof(Int32))
          {
            if (val == "")
              return 0;
            return Convert.ToInt32(val);
          }
          else if (Type == typeof(Int64))
          {
            if (val == "")
              return 0;
            return Convert.ToInt64(val);
          }
          else if (Type == typeof(Byte))
          {
            if (val == "")
              val = "0";
            return Convert.ToByte(val);
          }
          else if (Type == typeof(DateTime))
          {
            if (val == "")
              return DateTime.Now;
            return Convert.ToDateTime(val);
          }
          else if (Type == typeof(Decimal))
          {
            if (val == "")
              return 0;
            return Convert.ToDecimal(val);
          }
          else if (Type == typeof(Double))
          {
            if (val == "")
              return 0;
            return Convert.ToDouble(val);
          }
          else if (Type == typeof(Single))
          {
            if (val == "")
              return 0;
            return Convert.ToSingle(val);
          }
          else if (Type == typeof(StringBuilder))
          {
            if (val == "")
              return new StringBuilder("");
            return new StringBuilder(val);
          }
          else
            return val;
        }
        else if( Control is CheckBox )
          return ( (CheckBox) Control ).IsChecked;
        else
          throw new Exception( "Unknown control type" );
      }
    }

    public override String ToCode( String name )
    {
      StringBuilder sb = new StringBuilder();
      sb.Append( "    " ).Append( name ).Append( " = " );

      if( Type == typeof( String ) || Type == typeof( StringBuilder ) )
        sb.Append( "\"" ).Append( Value.ToString() ).Append( "\"" );
      else if( Type == typeof( char ) )
        sb.Append( "\'" ).Append( Value.ToString() ).Append( "\'" );
      else if( Type == typeof( bool ) )
        sb.Append( Value.ToString() );
      else if( Type == typeof( DateTime ) )
        sb.Append( "DateTime.Parse( \"" ).Append( Value.ToString() ).Append( "\" );" );

      sb.Append( ";\n" );
      return sb.ToString();
    }

    public override Control GetControl()
    {
      if( this.Type == typeof( Boolean ) )
      {
        CheckBox checkBox = new CheckBox();
        checkBox.Margin = new Thickness( 5, 0, 0, 0 );
        checkBox.VerticalAlignment = VerticalAlignment.Center;
        checkBox.HorizontalAlignment = HorizontalAlignment.Center;
        checkBox.Padding = new Thickness( 0, 0, 0, 0 );
        checkBox.Height = 80;
        Control = checkBox;
        return checkBox;
      }/*
        else if( parameterType == typeof( DateTime ) )
        {
          System.Windows.Controls.DatePicker datepicker = new DatePicker();
          datepicker.Margin = new Thickness(5, 0, 0, 0);
          datepicker.VerticalAlignment = VerticalAlignment.Center;
          datepicker.HorizontalAlignment = HorizontalAlignment.Center;
          datepicker.Height = 15;
          return datepicker;
        }*/
      else
      {
        TextBox textBox = new TextBox();
        //textBox.Background = null;
        textBox.Margin = new Thickness( 5, 0, 0, 0 );
        textBox.Padding = new Thickness( 0, 0, 0, 0 );
        //textBox.BorderBrush = null;
        //textBox.BorderThickness = new Thickness( 0 );
        textBox.VerticalAlignment = VerticalAlignment.Center;
        textBox.HorizontalAlignment = HorizontalAlignment.Left;
        textBox.Height = 50;
        textBox.Width = 180;
        textBox.FontSize = 14;

        if( this.Type.IsPrimitive && this.Type != typeof( Char ) )
        {
          textBox.InputScope = new InputScope();
          textBox.InputScope.Names.Add( new InputScopeName { NameValue = InputScopeNameValue.Number } );
        }
        Control = textBox;
        return textBox;
      }
    }
  }
}
