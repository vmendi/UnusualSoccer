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
  internal class ArrayInfo : ArgInfo
  {
    public Type ArrayElementType { get; set; }
    public List<ArgInfo> ArrayModel { get; set; }

    public ArrayInfo()
    {
      ArrayModel = new List<ArgInfo>();
    }

    public override Object Value
    {
      get
      {
        Array arrObj = Array.CreateInstance( ArrayElementType, ArrayModel.Count );

        for( int i = 0; i < ArrayModel.Count; i++ )
          arrObj.SetValue( ArrayModel[ i ].Value, i );

        return arrObj;
      }
    }

    public override List<UIElement> RenderRow( String name, ref int row, int padding )
    {
      List<UIElement> rowObj = new List<UIElement>();

      rowObj.Add( ViewHelper.setBorder( row, 0 ) );
      rowObj.Add( ViewHelper.setLabel( new String( ' ', padding * 2 ) + name, row, 0 ) );
      rowObj.Add( ViewHelper.setBorder( row, 1 ) );
      rowObj.Add( ViewHelper.setLabel( "Array", row, 1 ) );
      HyperlinkButton hyperlinkButton = (HyperlinkButton) GetControl();

      hyperlinkButton.Click += new RoutedEventHandler( Model.AddArrayItem );
      hyperlinkButton.SetValue( Grid.RowProperty, row );
      hyperlinkButton.SetValue( Grid.ColumnProperty, 2 );
      rowObj.Add( ViewHelper.setBorder( row, 2 ) );
      rowObj.Add( hyperlinkButton );

      for( int i = 0; i < ArrayModel.Count; i++ )
      {
        row++;
        rowObj.AddRange( ArrayModel[ i ].RenderRow( new String( ' ', padding * 2 ) + "[" + i + "]", ref row, padding + 1 ) );
      }

      return rowObj;
    }

    public override String ToCode( String name )
    {
      StringBuilder sb = new StringBuilder();

      sb.Append( "    " ).Append( name ).Append( " = new " ).Append( ArrayElementType.Name ).Append( "[];\n" );

      for( int i = 0; i < ArrayModel.Count; i++ )
        sb.Append( ArrayModel[ i ].ToCode( name + "[" + i + "]" ) );

      return sb.ToString();
    }

    public void AddChildRow()
    {
      ArgInfo child = Model.CreateArgInfo( ArrayElementType );
      ArrayModel.Add( child );
    }

    public override void Cleanup()
    {
      ArrayModel.Clear();
    }

    public override Control GetControl()
    {
      HyperlinkButton hyperlinkbutton = new HyperlinkButton();
      hyperlinkbutton.Height = 15;
      hyperlinkbutton.VerticalAlignment = VerticalAlignment.Center;
      hyperlinkbutton.Margin = new Thickness( 5, 0, 0, 0 );
      hyperlinkbutton.HorizontalAlignment = HorizontalAlignment.Left;
      hyperlinkbutton.Foreground = new SolidColorBrush( Colors.White );
      hyperlinkbutton.BorderThickness = new System.Windows.Thickness( 0 );
      hyperlinkbutton.Content = "Add Item";
      hyperlinkbutton.Tag = this;
      return hyperlinkbutton;
    }
  }
}
