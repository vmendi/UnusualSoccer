using System;
using System.Reflection;

namespace Invoker
{
    public partial class Page
    {
        const string CLASS_NAME = "SilverlightClassLibrary.TestClass";
        Assembly testAssembly = Assembly.Load( "SilverlightClassLibrary, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" );
    }
}

