using System;
using System.Collections.Generic;
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;

namespace Invoker.ViewModels
{
  internal class GenericInfo : ArrayInfo
  {
    public GenericInfo()
    {
      ArrayModel = new List<ArgInfo>();
    }

    public override Object Value
    {
      get
      {
        Object obj = Activator.CreateInstance(Type);
        var addMethod = Type.GetMethod("Add");

        for (int i = 0; i < ArrayModel.Count; i++)
          addMethod.Invoke(obj, new object[] { ArrayModel[i].Value });

        return obj;
      }
    }

    public static bool IsSupported(Type type)
    {
      if (type.GetGenericArguments().Length > 1)
        return false;
      if (type.GetMethod("Add") == null)
        return false;
      return true;
    }
  }
}