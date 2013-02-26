<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">

 
  <xsl:import href="codegen.xslt"/>
  <xsl:import href="codegen.invoke.xslt"/>
  <xsl:import href="sl-c-sharp-mono.xslt"/>
  <xsl:import href="sl-c-sharp-vs-browser.xslt"/>
  <xsl:import href="sl-c-sharp-vs-wp7.xslt"/> 

<xsl:param name="xsltExtension" />


<xsl:template name="codegen.appmain">
</xsl:template>

  <xsl:template name="comment.service">
  /***********************************************************************
  The generated code provides a simple mechanism for invoking methods
  from the <xsl:value-of select="@fullname" /> class using WebORB Silverlight. 
  client API.
  The generated files can be added to a Visual Studio 2008/2010 Silverlight
  library project. You can compile the library and use it from other Silverlight
  component projects.
  ************************************************************************/
  </xsl:template>
 
  <xsl:template name="codegen.process.fullproject">
    <xsl:param name="file-name" select="codegen:getServiceName()"/>
    <xsl:param name="projectGuid" select="codegen:getGuid()"/>
      <xsl:call-template name="main-vs">
        <xsl:with-param name="file-name" select="$file-name"/>
        <xsl:with-param name="projectGuid" select="$projectGuid"/>  
      </xsl:call-template>
      <xsl:call-template name="main-mono">
       <xsl:with-param name="file-name" select="$file-name"/>
       <xsl:with-param name="projectGuid" select="$projectGuid"/>  
     </xsl:call-template>
      <xsl:call-template name="main-wp7">
       <xsl:with-param name="file-name" select="$file-name"/>
       <xsl:with-param name="projectGuid" select="$projectGuid"/>  
     </xsl:call-template>
    </xsl:template>
  
<xsl:template name="service-model">
    <xsl:param name="file-name"/>  
	<file name="Page.cs">
using System;
using System.Reflection;

namespace Invoker
{
    public partial class Page
    {
        const string CLASS_NAME = "<xsl:value-of select="//service[ 1 ]/@fullname"/>Service";
        Assembly testAssembly = Assembly.Load( "<xsl:value-of select="$file-name"/>, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" );
    }
}	
	</file>
	
	<file name="ServiceModel.cs">
using System;
using System.Collections;
using System.Collections.Generic;
using Weborb.Client;

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
		
		<xsl:for-each select="//service">
		<xsl:for-each select="method">
		public void <xsl:value-of select="@name"/>ResultHandler( <xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose> ReturnObj )
		{
		  DisplayResult( ReturnObj );
		}
		</xsl:for-each>
		</xsl:for-each>
		
      private void DisplayResult( object result )
      {
        Type returnType = result.GetType();
        page.ClearGrid( page.ResultdataGrid );
        page.TypeAnalyzer( returnType, page.ResultdataGrid.RowDefinitions.Count, result, "Result" );
      }		
    }
}	
	</file>	 
</xsl:template>    

<xsl:template name="assembly-info">
    <xsl:param name="projectGuid"/>
    <xsl:param name="file-name"/>
      <folder name="Properties">
        <file name="AssemblyInfo.cs">
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

// General Information about an assembly is controlled through the following
// set of attributes. Change these attribute values to modify the information
// associated with an assembly.
[assembly: AssemblyTitle("<xsl:value-of select="$file-name"/>")]
[assembly: AssemblyDescription("")]
[assembly: AssemblyConfiguration("")]
[assembly: AssemblyCompany("")]
[assembly: AssemblyProduct("<xsl:value-of select="$file-name"/>")]
[assembly: AssemblyCopyright("")]
[assembly: AssemblyTrademark("")]
[assembly: AssemblyCulture("")]

// Setting ComVisible to false makes the types in this assembly not visible
// to COM components.  If you need to access a type in this assembly from
// COM, set the ComVisible attribute to true on that type.
[assembly: ComVisible(false)]

// The following GUID is for the ID of the typelib if this project is exposed to COM
[assembly: Guid("<xsl:value-of select="$projectGuid"/>")]

// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version
//      Build Number
//      Revision
//
// You can specify all the values or you can default the Revision and Build Numbers
// by using the '*' as shown below:
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
        </file>
      </folder>
</xsl:template>

  <xsl:template name="codegen.service">
      <file name="{@name}Service.cs">
        <xsl:call-template name="codegen.code" />
      </file>
      <file name="I{@name}.cs">
        <xsl:call-template name="codegen.interface" />
      </file>
      <file name="{@name}Model.cs">
        <xsl:call-template name="codegen.model" />
      </file>     
  </xsl:template>

  <xsl:template name="codegen.vo.folder">
    <xsl:if test="count(datatype) != 0 or count(enum) != 0">
      <folder name="Types">
        <xsl:for-each select="datatype">
          <xsl:call-template name="codegen.sl.vo" />
        </xsl:for-each>
        <xsl:for-each select="enum">
          <xsl:call-template name="codegen.sl.enum" />
        </xsl:for-each>
      </folder>
    </xsl:if>
  </xsl:template>

  <xsl:template name="codegen.sl.enum">
      <file name="{@name}.cs">
          <xsl:call-template name="codegen.description">
              <xsl:with-param name="file-name" select="concat(@name,'.cs')" />
          </xsl:call-template>
          using System;
          using System.Collections;
          using System.Collections.Generic;
          <!--<xsl:for-each select="//datatype[not(preceding-sibling::datatype/@typeNamespace=@typeNamespace or @typeNamespace = current()/@typeNamespace)]">
        using <xsl:value-of select="@typeNamespace" />;
      </xsl:for-each>
      <xsl:for-each select="//enum[not(preceding-sibling::datatype/@typeNamespace=@typeNamespace or //datatype/@typeNamespace=@typeNamespace or @typeNamespace = current()/@typeNamespace)]">
        using <xsl:value-of select="@typeNamespace" />;
      </xsl:for-each>-->
          namespace <xsl:value-of select="@typeNamespace" />
          {
          public enum <xsl:value-of select="@name"/> <xsl:if test="@parentName">
              : <xsl:value-of select="@parentNamespace"/>.<xsl:value-of select="@parentName"/>
          </xsl:if>
            {
              <xsl:for-each select="field">
                <xsl:value-of select="@name"/><xsl:if test="position() != last()">,</xsl:if>
              </xsl:for-each>
            }
          }
      </file>
  </xsl:template>

  <xsl:template name="codegen.sl.vo">
    <file name="{@name}.cs">
      <xsl:call-template name="codegen.description">
        <xsl:with-param name="file-name" select="concat(@name,'.cs')" />
      </xsl:call-template>
      using System;
      using System.Collections;
      using System.Collections.Generic;
      using System.Text;
      <!--<xsl:for-each select="//datatype[not(preceding-sibling::datatype/@typeNamespace=@typeNamespace or @typeNamespace = current()/@typeNamespace)]">
        using <xsl:value-of select="@typeNamespace" />;
      </xsl:for-each>
      <xsl:for-each select="//enum[not(preceding-sibling::datatype/@typeNamespace=@typeNamespace or //datatype/@typeNamespace=@typeNamespace or @typeNamespace = current()/@typeNamespace)]">
        using <xsl:value-of select="@typeNamespace" />;
      </xsl:for-each>-->
       namespace <xsl:value-of select="@typeNamespace" />
        {
        public class <xsl:value-of select="@name"/> <xsl:if test="@parentName"> : <xsl:value-of select="@parentNamespace"/>.<xsl:value-of select="@parentName"/></xsl:if>
        {
        <xsl:for-each select="const">
          public const <xsl:value-of select="@nativetype"/><xsl:text> </xsl:text><xsl:value-of select="@name"/> = <xsl:if test="@type='String'">"</xsl:if><xsl:value-of select="@value"/><xsl:if test="@type='String'">"</xsl:if>;
        </xsl:for-each>
        <xsl:for-each select="field">
          public <xsl:value-of select="@nativetype"/><xsl:text> </xsl:text><xsl:value-of select="@name"/>;
        </xsl:for-each>
        }
      }
    </file>
  </xsl:template>  
  
  <xsl:template name="codegen.invoke.method.name">
    m_service.<xsl:value-of select="@name"/>
  </xsl:template>
  
  <xsl:template name="codegen.code">
    <xsl:call-template name="codegen.description">
      <xsl:with-param name="file-name" select="concat(concat(@name,'Service'),'.cs')" />
    </xsl:call-template>
    <xsl:call-template name="comment.service" />
using System;
using System.Collections;
using System.Collections.Generic;
using System.Windows.Controls;
using Weborb.Client;
    <xsl:for-each select="//namespace[datatype]">
using <xsl:value-of select="@fullname" />;
    </xsl:for-each>

namespace <xsl:value-of select="@namespace" />
{
  public class <xsl:value-of select="@name"/>Service
  {
    private WeborbClient weborbClient;
    private <xsl:value-of select="concat('I',@name)" /> proxy;
    private <xsl:value-of select="@name"/>Model model;

    public <xsl:value-of select="@name"/>Service() : this( new <xsl:value-of select="@name"/>Model(), null, null )
    {
    }
    
    public <xsl:value-of select="@name"/>Service( UserControl uiControl, String endpointURL ) : this( new <xsl:value-of select="@name"/>Model(), uiControl, endpointURL )
    {
    }    
      
    public <xsl:value-of select="@name"/>Service( <xsl:value-of select="@name"/>Model model, UserControl uiControl, String endpointURL )
    {
      this.model = model;
      weborbClient = new WeborbClient( endpointURL == null ? "<xsl:value-of select="@url"/>" : endpointURL, uiControl ); 
      proxy = weborbClient.Bind&lt;<xsl:value-of select="concat('I',@name)" />&gt;();
    }

    public <xsl:value-of select="@name"/>Model GetModel()
    {
      return this.model;
    }
    <xsl:for-each select="method">
    public <xsl:if test="@type='void'">void</xsl:if><xsl:if test="@type!='void'">AsyncToken&lt;<xsl:value-of select="@nativetype" />&gt;</xsl:if><xsl:text> </xsl:text><xsl:value-of select="@name"/>( <xsl:for-each select="arg"><xsl:value-of select="@nativetype" /><xsl:text> </xsl:text><xsl:value-of select="@name"/><xsl:if test="position() != last()">,</xsl:if><xsl:text> </xsl:text></xsl:for-each> )
    {<xsl:choose>
        <xsl:when test="@type != 'void'">
      return <xsl:value-of select="@name"/>(<xsl:for-each select="arg"><xsl:value-of select="@name"/>, </xsl:for-each> new Responder&lt;<xsl:value-of select="@nativetype" />&gt;( <xsl:value-of select="@name"/>ResultHandler, null ) );
    </xsl:when>
      <xsl:otherwise>
      <xsl:value-of select="@name"/>(<xsl:for-each select="arg"><xsl:value-of select="@name"/>, </xsl:for-each> new Responder&lt;<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose>&gt;( <xsl:value-of select="@name"/>ResultHandler, null) );
    </xsl:otherwise>
</xsl:choose>}

    public <xsl:if test="@type='void'">void</xsl:if><xsl:if test="@type!='void'">AsyncToken&lt;<xsl:value-of select="@nativetype" />&gt;</xsl:if><xsl:text> </xsl:text><xsl:value-of select="@name"/>( <xsl:for-each select="arg"><xsl:value-of select="@nativetype" /><xsl:text> </xsl:text><xsl:value-of select="@name"/>, </xsl:for-each>Responder&lt;<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose>&gt; responder )
    {   
      <xsl:if test="@type='void'">
        proxy.<xsl:value-of select="@name"/>(<xsl:for-each select="arg"><xsl:if test="position() != 1">,</xsl:if><xsl:value-of select="@name"/></xsl:for-each>);
      </xsl:if>
      <xsl:if test="@type!='void'">
      AsyncToken&lt;<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose>&gt;<xsl:text> </xsl:text> asyncToken = proxy.<xsl:value-of select="@name"/>(<xsl:for-each select="arg"><xsl:if test="position() != 1">,</xsl:if><xsl:value-of select="@name"/></xsl:for-each>);
      asyncToken.ResultListener += ( responder != null &amp;&amp; responder.ResponseHandler != null ? responder.ResponseHandler : <xsl:value-of select="@name" />ResultHandler );

      if(  responder != null &amp;&amp; responder.ErrorHandler != null )
	     asyncToken.ErrorListener += responder.ErrorHandler;      
      <xsl:if test="@type != 'void'">
       return asyncToken;</xsl:if>      
      </xsl:if>
    }
    </xsl:for-each>

    <xsl:for-each select="method">     
    void <xsl:value-of select="@name" />ResultHandler(<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose> result)
    {
      model.<xsl:value-of select="@name" />Result = result;
    }
    </xsl:for-each>
  }
} 
  </xsl:template>
  
  <xsl:template name="codegen.interface">
    <xsl:call-template name="codegen.description">
      <xsl:with-param name="file-name" select="concat('I',concat(@name,'.cs'))" />
    </xsl:call-template>
    using System;
    using System.Collections;
    using System.Collections.Generic;
    using Weborb.Client;
    <xsl:for-each select="//namespace[datatype]">
    using <xsl:value-of select="@fullname" />;
    </xsl:for-each>

    namespace <xsl:value-of select="@namespace" />
    {
      public interface I<xsl:value-of select="@name"/>
      {<xsl:for-each select="method">
        <xsl:choose>
            <xsl:when test="@type != 'void'">
                AsyncToken&lt;<xsl:value-of select="@nativetype" />&gt; <xsl:value-of select="@name"/>(<xsl:for-each select="arg"><xsl:value-of select="concat(@nativetype, ' ')" /> <xsl:value-of select="@name"/><xsl:if test="position() != last()">,</xsl:if></xsl:for-each>);
      </xsl:when>
            <xsl:otherwise>
                void <xsl:value-of select="@name"/>(<xsl:for-each select="arg"><xsl:value-of select="concat(@nativetype, ' ')" /> <xsl:value-of select="@name"/><xsl:if test="position() != last()">,</xsl:if></xsl:for-each>);
            </xsl:otherwise>
    </xsl:choose>
    </xsl:for-each>}
  } 
  </xsl:template>
  
  <xsl:template name="codegen.model">
    <xsl:call-template name="codegen.description">
      <xsl:with-param name="file-name" select="concat(@name,'Model.cs')" />
    </xsl:call-template>

    using System;
    using System.Collections;
    using System.Collections.Generic;
    <xsl:for-each select="//namespace[datatype]">
    using <xsl:value-of select="@fullname" />;
    </xsl:for-each>

    namespace <xsl:value-of select="@namespace" />
    { 
      public class <xsl:value-of select="@name"/>Model
      {<xsl:for-each select="method">  
        public <xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose><xsl:text> </xsl:text><xsl:value-of select="@name" />Result;</xsl:for-each>
      }
    }
  </xsl:template>
  
  <xsl:template name="codegen.instructions">
  <xsl:param name="file-name" select="codegen:getServiceName()"/>
    <file name="{$file-name}-instructions.txt" overwrite="false">
      The generated code enables remoting operations between a Silverlight client and the 
      selected service (<xsl:value-of select="$file-name"/>).
      
      Generated classes include:
      
      1. Service facade (<xsl:value-of select="//service/@namespace" />.<xsl:value-of select="$file-name"/>Service) - Contains the same 
          methods as the remote service. Includes functionality for creating a proxy, handling 
          RPC invocations and updating the model.
          
      2. Model class (<xsl:value-of select="//service/@namespace" />.<xsl:value-of select="$file-name"/>Model) - Contains properties 
         updated by the Service facade when it receives results from the remote method invocations.
          
      3. Remote service interface (<xsl:value-of select="//service/@namespace" />.I<xsl:value-of select="$file-name"/>) - An interface 
          with the same methods as the remote service, but modified return values to reflect 
          the asynchronous nature of the client/server invocations.
    </file>
  </xsl:template>  
</xsl:stylesheet>
