using System;
using System.Net;
using System.Collections.Generic;
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
  internal abstract class ArgInfo
  {
    public MainViewModel Model { get; set; }
    public abstract Object Value { get; }
    public String TypeName { get { return Type.Name; } }
    public virtual Type Type { get; set; }
    public abstract String ToCode( String name );
    public abstract List<UIElement> RenderRow( String name, ref int row, int padding );

    public virtual Control GetControl()
    {
      return null;
    }

    public virtual void Cleanup() { }
  }
}
