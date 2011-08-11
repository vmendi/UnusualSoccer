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

namespace Invoker
{
  public class ViewHelper
  {
    public static Border setBorder( int row, int col )
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

    public static Border setBorderTOTextBox( int row, int col )
    {
      Border border = new Border();
      border.Background = new SolidColorBrush( Colors.White );
      border.Margin = new Thickness( 5, 0, 0, 0 );
      //border.CornerRadius = new CornerRadius( 6 );
      border.HorizontalAlignment = HorizontalAlignment.Left;
      border.VerticalAlignment = VerticalAlignment.Center;
      //border.Height = 20;
      //border.Width = 150;
      border.OpacityMask = new SolidColorBrush( Colors.White );
      border.BorderThickness = new Thickness( 1, 1, 1, 1 );
      border.BorderBrush = new SolidColorBrush( Colors.White );
      border.SetValue( Grid.RowProperty, row );
      border.SetValue( Grid.ColumnProperty, col );
      return border;
    }

    public static TextBlock setLabel( string text, int row, int col )
    {
      TextBlock label = new TextBlock();
      label.Text = text;
      label.Margin = new Thickness( 5, 1, 1, 1 );
      label.SetValue( Grid.ColumnProperty, col );
      label.SetValue( Grid.RowProperty, row );
      return label;
    }

    public static void ClearGrid( Grid grid )
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
  }
}
