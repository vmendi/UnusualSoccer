
using System;
using Weborb.Client;
using System.Collections.Generic;
using System.Collections;

namespace Invoker
{
    public class ServiceModel
    {
    	private Page page;
    	
    	public ServiceModel( Page page )
    	{
    	  this.page = page;
    	}
    	
		public void ErrorHandler( Fault fault )
		{
			System.Windows.Browser.HtmlPage.Window.Alert( " in fault - " + fault.Message );
		}
		
		
		public void echoArrayResultHandler( List<String> ReturnObj )
		{
		  DisplayResult( ReturnObj );
		}
		
		public void echoComplexTypeResultHandler( Weborb.Examples.InvocationTests.ComplexType ReturnObj )
		{
		  DisplayResult( ReturnObj );
		}
		
		public void getElementsResultHandler( List<IDictionary> ReturnObj )
		{
		  DisplayResult( ReturnObj );
		}
		
		public void getStringArrayResultHandler( String[] ReturnObj )
		{
		  DisplayResult( ReturnObj );
		}
		
		
      private void DisplayResult( object result )
      {
        Type returnType = result == null ? typeof(Nullable) : result.GetType();
        page.ClearGrid( page.ResultdataGrid );
        page.TypeAnalyzer( returnType, page.ResultdataGrid.RowDefinitions.Count, result, "Result" );
      }		
    }
}	
	