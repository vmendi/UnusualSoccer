using System;
using System.Collections.Generic;
using System.Reflection;
using System.Text;

namespace Invoker.ViewModels
{
  internal class PageModel
  {
    private Dictionary<MethodInfo, Dictionary<string, ArgInfo>> methods = new Dictionary<MethodInfo, Dictionary<string, ArgInfo>>();
    public MethodInfo SelectedMethod { get; set; }
    public Page Controller { get; set; }

    public PageModel( Page controller )
    {
      Controller = controller;
    }

    public void AddToModel( MethodInfo method )
    {
      ParameterInfo[] args = method.GetParameters();
      Dictionary<string,ArgInfo> argInfos = new Dictionary<string,ArgInfo>( args.Length );

      for( int i = 0; i < args.Length; i++ )
        argInfos[ "arg" + i ] = CreateArgInfo( args[ i ].ParameterType );

      methods.Add( method, argInfos );
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
          throw new Exception(type.FullName + " not supported");
        GenericInfo genericInfo = new GenericInfo();
        genericInfo.ArrayElementType = type.GetGenericArguments()[0];
        argInfo = genericInfo;
      }
      else if( type.IsPrimitive || type == typeof( String ) || type == (typeof( StringBuilder ) ) || type == typeof( DateTime ) || type == typeof( Object ) )
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

    public Dictionary<String, ArgInfo> CurrentMethodArgInfo
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
        return SelectedMethod.Name;
      }
    }
  }
}