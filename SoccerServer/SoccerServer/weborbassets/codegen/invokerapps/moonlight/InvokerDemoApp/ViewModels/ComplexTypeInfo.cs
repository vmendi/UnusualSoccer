using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace Invoker.ViewModels
{
  internal class ComplexTypeInfo : ArgInfo
  {
    public Dictionary<string, ArgInfo> ComplexTypeModel { get; set; }

    public ComplexTypeInfo()
    {
      ComplexTypeModel = new Dictionary<string, ArgInfo>();
    }

    public bool Expanded { get; set; }

    private HyperlinkButton _collapseExpandButton = new HyperlinkButton();
    public HyperlinkButton CollapseExpandButton
    {
      get
      {
        return _collapseExpandButton;
      }
    }

    private RoutedEventHandler _expandEventHandler = new RoutedEventHandler(Page.ExpandItem);
    private RoutedEventHandler _collapseEventHandler = new RoutedEventHandler(Page.CollapseItem);

    private bool _initialized;
    public void InitializeMembers()
    {
      if (_initialized)
        return;
      MemberInfo[] members = Type.GetMembers(BindingFlags.Public | BindingFlags.Instance);

      foreach (MemberInfo member in members)
        if (member is PropertyInfo || member is FieldInfo)
          ComplexTypeModel[member.Name] = Model.CreateArgInfo(member is PropertyInfo ? ((PropertyInfo)member).PropertyType : ((FieldInfo)member).FieldType);
      _initialized = true;
    }

    public override List<UIElement> RenderRow(String name, ref int row, int padding)
    {
      List<UIElement> rowObj = new List<UIElement>();
      rowObj.Add(Model.Controller.setBorder(row, 0));
      rowObj.Add(Model.Controller.setLabel(new String(' ', padding * 2) + name, row, 0));
      rowObj.Add(Model.Controller.setBorder(row, 1));
      rowObj.Add(Model.Controller.setLabel(TypeName, row, 1));
      rowObj.Add(Model.Controller.setBorder(row, 2));

      HyperlinkButton hyperlinkButton = (HyperlinkButton)GetControl();

      hyperlinkButton.SetValue(Grid.RowProperty, row);
      hyperlinkButton.SetValue(Grid.ColumnProperty, 2);
      rowObj.Add(hyperlinkButton);

      if (Expanded)
      {
        CollapseExpandButton.Click += _collapseEventHandler;
        CollapseExpandButton.Content = "Collapse";
        CollapseExpandButton.Click -= _expandEventHandler;
        foreach (KeyValuePair<String, ArgInfo> prop in ComplexTypeModel)
        {
          row++;
          rowObj.AddRange(prop.Value.RenderRow(new String(' ', padding * 2) + prop.Key, ref row, padding + 1));
        }
      }
      else
      {
        CollapseExpandButton.Click -= _collapseEventHandler;
        CollapseExpandButton.Content = "Expand";
        CollapseExpandButton.Click += _expandEventHandler;
      }

      return rowObj;
    }

    public void Expand()
    {
      Expanded = true;
      InitializeMembers();
    }

    public void Collapse()
    {
      Expanded = false;
    }

    public override Object Value
    {
      get
      {
        Object obj = Activator.CreateInstance( Type );

        foreach( String key in ComplexTypeModel.Keys )
        {
          PropertyInfo propInfo = Type.GetProperty( key );

          if( propInfo != null )
            propInfo.SetValue( obj, ComplexTypeModel[ key ].Value, null );
          else
          {
            FieldInfo field = Type.GetField( key );
            field.SetValue( obj, ComplexTypeModel[ key ].Value );
          }
        }

        return obj;
      }
    }

    public override String ToCode( String name )
    {
      StringBuilder sb = new StringBuilder();
      sb.Append( "    " ).Append( name ).Append( " = " ).Append( "new " ).Append( Type.Name ).Append( "();\n" );

      foreach( String key in ComplexTypeModel.Keys )
        sb.Append( ComplexTypeModel[ key ].ToCode( name + "." + key ) );

      return sb.ToString();
    }

    public override Control GetControl()
    {
      HyperlinkButton hyperlinkbutton = CollapseExpandButton;
      hyperlinkbutton.Height = 15;
      hyperlinkbutton.VerticalAlignment = VerticalAlignment.Center;
      hyperlinkbutton.Margin = new Thickness(5, 0, 0, 0);
      hyperlinkbutton.HorizontalAlignment = HorizontalAlignment.Left;
      hyperlinkbutton.Foreground = new SolidColorBrush(Colors.White);
      hyperlinkbutton.BorderThickness = new System.Windows.Thickness(0);
      hyperlinkbutton.Tag = this;
      return hyperlinkbutton;
    }
  }
}