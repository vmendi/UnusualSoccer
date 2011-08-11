using System;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;

namespace Invoker.ViewModels
{
  internal abstract class ArgInfo
  {
    public PageModel Model { get; set; }
    public abstract Object Value {get;}
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