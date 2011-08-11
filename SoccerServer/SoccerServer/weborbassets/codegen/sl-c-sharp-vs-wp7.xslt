<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">
<xsl:template name="main-wp7">
<xsl:param name="file-name" />
<xsl:param name="projectGuid" />     
  <folder name="WindowsPhone">
  <folder name="InvokerDemoApp">
    <file path="../silverlight/windowsphone/WeborbPhoneClient.dll" hideContent="true"/>  
    <file path="invokerapps/windowsphone/InvokerDemoApp/App.xaml" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/App.xaml.cs" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/DetailsPage.xaml" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/DetailsPage.xaml.cs" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/ErrorPage.xaml" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/ErrorPage.xaml.cs" />    
    <file path="invokerapps/windowsphone/InvokerDemoApp/MainPage.xaml" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/MainPage.xaml.cs" />        
    <file path="invokerapps/windowsphone/InvokerDemoApp/ResultPage.xaml" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/ResultPage.xaml.cs" />     
    <file path="invokerapps/windowsphone/InvokerDemoApp/WebORBURLPage.xaml" />
    <file path="invokerapps/windowsphone/InvokerDemoApp/WebORBURLPage.xaml.cs" />   
    <file path="invokerapps/windowsphone/InvokerDemoApp/InvokerApp.csproj" />     
    <file path="invokerapps/windowsphone/InvokerDemoApp/InvokerApp.csproj.user" />      
    <file path="invokerapps/windowsphone/InvokerDemoApp/SplashScreenImage.jpg" />       
    <folder name="SampleData">
        <file path="invokerapps/windowsphone/InvokerDemoApp/SampleData/MainViewModelSampleData.xaml" />  
    </folder>       
    <folder name="ViewModels">
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/ArgInfo.cs" />      
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/ArrayInfo.cs" />
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/GenericInfo.cs" />
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/ComplexTypeInfo.cs" />    
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/ItemViewModel.cs" />    
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/MainViewModel.cs" />    
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/PrimitiveInfo.cs" />    
        <file path="invokerapps/windowsphone/InvokerDemoApp/ViewModels/ViewHelper.cs" />        
        <xsl:call-template name="service-lib-info-class" />
        <xsl:call-template name="service-model-class" />        
    </folder>
    <folder name="Properties">
      <file path="invokerapps/windowsphone/InvokerDemoApp/Properties/AppManifest.xml" />
      <file path="invokerapps/windowsphone/InvokerDemoApp/Properties/AssemblyInfo.cs" />
      <xsl:call-template name="wmmanifest">
        <xsl:with-param name="service-name" select="$file-name" />
      </xsl:call-template>    
    </folder>
    <folder name="Images">
      <file path="invokerapps/windowsphone/InvokerDemoApp/Images/Background.png" />
      <file path="invokerapps/windowsphone/InvokerDemoApp/Images/ApplicationIcon.png" />   
      <file path="invokerapps/windowsphone/InvokerDemoApp/Images/appbar.feature.settings.rest.png" />          
    </folder>
    <xsl:call-template name="service-model">
       <xsl:with-param name="file-name" select="$file-name"/>
    </xsl:call-template>   
  </folder>
  <folder name="RemoteServiceLibrary">
    <xsl:call-template name="codegen.project.file.vs.wp7">
      <xsl:with-param name="file-name" select="$file-name"/>
      <xsl:with-param name="projectGuid" select="$projectGuid"/>
    </xsl:call-template>    
    <xsl:call-template name="assembly-info">
       <xsl:with-param name="file-name" select="$file-name"/>
       <xsl:with-param name="projectGuid" select="$projectGuid"/>
    </xsl:call-template>
    <xsl:for-each select="/namespaces">
      <xsl:call-template name="codegen.process.namespace.wp7" />
    </xsl:for-each>
    <file path="../silverlight/windowsphone/WeborbPhoneClient.dll" hideContent="true"/>  
  </folder>
  <xsl:call-template name="codegen.sln.file.vs.wp7">
     <xsl:with-param name="projectName" select="$file-name"/>  
     <xsl:with-param name="projectGuid" select="$projectGuid"/>
  </xsl:call-template>  
 </folder>    
    </xsl:template>
    
<!-- ************************************************************************************** -->
<!-- ****   Generates WMAppManifest file for the WP7 app deployment              ********** -->
<!-- ************************************************************************************** -->        
<xsl:template name="wmmanifest">
<xsl:param name="service-name"/>    
<file name="WMAppManifest.xml" type="xml">
<Deployment xmlns="http://schemas.microsoft.com/windowsphone/2009/deployment" AppPlatformVersion="7.0">
  <App xmlns=""  Title="{$service-name}Invoker" RuntimeType="Silverlight" Version="1.0.0.0" Genre="apps.normal" Author="Midnight Coders, Inc." Description="Sample description" Publisher="You">
<xsl:attribute name="ProductID">{16aa73db-4f46-4670-9c5f-10acb91acace}</xsl:attribute>
        <IconPath IsRelative="true" IsResource="false">ApplicationIcon.png</IconPath>
    <Capabilities>
      <Capability Name="ID_CAP_GAMERSERVICES" />
      <Capability Name="ID_CAP_IDENTITY_DEVICE" />
      <Capability Name="ID_CAP_IDENTITY_USER" />
      <Capability Name="ID_CAP_LOCATION" />
      <Capability Name="ID_CAP_MEDIALIB" />
      <Capability Name="ID_CAP_MICROPHONE" />
      <Capability Name="ID_CAP_NETWORKING" />
      <Capability Name="ID_CAP_PHONEDIALER" />
      <Capability Name="ID_CAP_PUSH_NOTIFICATION" />
      <Capability Name="ID_CAP_SENSORS" />
      <Capability Name="ID_CAP_WEBBROWSERCOMPONENT" />
    </Capabilities>
    <Tasks>
      <DefaultTask Name="_default" NavigationPage="MainPage.xaml" />
    </Tasks>
    <Tokens>
      <PrimaryToken TokenID="{$service-name}Token" TaskName="_default">
        <TemplateType5>
          <BackgroundImageURI IsRelative="true" IsResource="false">Background.png</BackgroundImageURI>
          <Count>0</Count>
          <Title><xsl:value-of select="$service-name" /> Invoker</Title>
        </TemplateType5>
      </PrimaryToken>
    </Tokens>
  </App>
</Deployment>
</file>
</xsl:template>      

<!-- ************************************************************************************** -->
<!-- ****   Need to override namespace processing because WP7 service looks      ********** -->
<!-- ****   different than the same class for SL or Mono                         ********** -->
<!-- ************************************************************************************** -->        
    <xsl:template name="codegen.process.namespace.wp7">
        <xsl:for-each select="namespace">
            <folder name="{@name}">
                <xsl:call-template name="codegen.process.namespace.wp7" />              
                <xsl:for-each select="service">
                    <xsl:call-template name="codegen.service.wp7" />
                </xsl:for-each>     
                 <xsl:call-template name="codegen.vo.folder" />                 
            </folder>
        </xsl:for-each>
    </xsl:template>    
    
<!-- ************************************************************************************** -->
<!-- ****   Service generation for WP7.                                          ********** -->
<!-- ************************************************************************************** -->
    
  <xsl:template name="codegen.service.wp7">
      <file name="{@name}Service.cs">
        <xsl:call-template name="codegen.code.wp7" />
      </file>
      <file name="{@name}Model.cs">
        <xsl:call-template name="codegen.model" />
      </file>     
  </xsl:template>    
    
<!-- *********************************************************************************** -->
<!-- ****   Main class for the client-side service proxy. Contains all the    ********** -->
<!-- ****   methods from the corresponding remote class                       ********** -->
<!-- *********************************************************************************** -->
  <xsl:template name="codegen.code.wp7">
    <xsl:call-template name="codegen.description">
      <xsl:with-param name="file-name" select="concat(concat(@name,'Service'),'.cs')" />
    </xsl:call-template>
    <xsl:call-template name="comment.service" />
using System;
using System.Windows;
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
      weborbClient = new WeborbClient( endpointURL == null ? "<xsl:value-of select="//runtime/@serverRootURL"/>" : endpointURL, uiControl ); 
    }

    public <xsl:value-of select="@name"/>Model GetModel()
    {
      return this.model;
    }
    <xsl:for-each select="method">
    public void <xsl:value-of select="@name"/>( <xsl:for-each select="arg"><xsl:value-of select="@nativetype" /><xsl:text> </xsl:text><xsl:value-of select="@name"/>, </xsl:for-each>Responder&lt;<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose>&gt; responder )
    {
      if( responder == null )
        responder = new Responder&lt;<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose>&gt;( <xsl:value-of select="@name" />ResultHandler, ErrorHandler );
      
      weborbClient.Invoke&lt;<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose>&gt;( "<xsl:value-of select="../@namespace" />.<xsl:value-of select="../@name"/>", "<xsl:value-of select="@name"/>", new object[] { <xsl:for-each select="arg"><xsl:value-of select="@name"/><xsl:if test="position() != last()">, </xsl:if></xsl:for-each>}, responder );
    }
    </xsl:for-each>

    <xsl:for-each select="method">     
    void <xsl:value-of select="@name" />ResultHandler(<xsl:choose><xsl:when test="@type = 'void'">Object</xsl:when><xsl:otherwise><xsl:value-of select="@nativetype"/></xsl:otherwise></xsl:choose> result)
    {
      model.<xsl:value-of select="@name" />Result = result;
    }
    </xsl:for-each>
    
    public void ErrorHandler( Fault fault )
    {
        Deployment.Current.Dispatcher.BeginInvoke( new Action( () =>
        {
          MessageBox.Show( "WebORB URL is valid", "Success", MessageBoxButton.OK );
        } ) );    
    }
  }
} 
  </xsl:template>

<!-- ********************************************************************************* -->
<!-- ****   ServiceLibInfo class. Contains information about the service    ********** -->
<!-- ****   library sub-project.                                            ********** -->
<!-- ********************************************************************************* -->
<xsl:template name="service-lib-info-class">
  <file name="ServiceLibInfo.cs">
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
using System.Reflection;

namespace Invoker
{
  public class ServiceLibInfo
  {
    internal const string CLASS_NAME = "<xsl:value-of select="//service[ 1 ]/@fullname" />Service";
    internal static Assembly testAssembly = Assembly.Load( "RemoteServiceLibrary, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null" );
    internal static String WEBORB_URL = "<xsl:value-of select="//runtime/@weborbRootURL"/>/weborb.aspx";
  }
}    
  </file>
</xsl:template>        

<xsl:template name="service-model-class">
    <file name="ServiceModel.cs">
using System;
using System.Collections.Generic;
using System.Net;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Documents;
using System.Windows.Ink;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Animation;
using System.Windows.Shapes;
using System.Windows.Navigation;
using Weborb.Client;
using System.Collections;

namespace Invoker
{
  public class ServiceModel
  {
    private DetailsPage page;

    public ServiceModel( DetailsPage page )
    {
      this.page = page;
    }

    public void ErrorHandler( Fault fault )
    {
      App.ViewModel.ErrorText = fault.Message;
      page.Dispatcher.BeginInvoke(() => page.NavigationService.Navigate(new Uri("/ErrorPage.xaml", UriKind.Relative)));
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
      App.ViewModel.Result = result;
      page.NavigationService.Navigate( new Uri( "/ResultPage.xaml", UriKind.Relative ) );
    }   
  }
}   
    </file>  
</xsl:template>    

<!-- ********************************************************************************* -->
<!-- ****   Generates project file for the class library project which        ******** -->
<!-- ****   contains all the "plumbing" code generated from the backend svc   ******** -->
<!-- ********************************************************************************* -->

  <xsl:template name="codegen.project.file.vs.wp7">
    <xsl:param name="file-name"/>
    <xsl:param name="projectGuid"/>
    <file name="RemoteServiceLibrary.csproj" type="xml" addxmlversion="true">
<Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProductVersion>10.0.20506</ProductVersion>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>{<xsl:value-of select="$projectGuid"/>}</ProjectGuid>
    <ProjectTypeGuids>{C089C8C0-30E0-4E22-80C0-CE093F111A43};{fae04ec0-301f-11d3-bf4b-00c04f79efbc}</ProjectTypeGuids>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>invoker</RootNamespace>
    <AssemblyName>RemoteServiceLibrary</AssemblyName>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <SilverlightVersion>$(TargetFrameworkVersion)</SilverlightVersion>
    <TargetFrameworkProfile>WindowsPhone</TargetFrameworkProfile>
    <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
    <SilverlightApplication>false</SilverlightApplication>
    <ValidateXaml>true</ValidateXaml>
    <ThrowErrorsInValidation>true</ThrowErrorsInValidation>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <DebugSymbols>true</DebugSymbols>
    <DebugType>full</DebugType>
    <Optimize>false</Optimize>
    <OutputPath>Bin\Debug</OutputPath>
    <DefineConstants>DEBUG;TRACE;SILVERLIGHT;WINDOWS_PHONE</DefineConstants>
    <NoStdLib>true</NoStdLib>
    <NoConfig>true</NoConfig>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <DebugType>pdbonly</DebugType>
    <Optimize>true</Optimize>
    <OutputPath>Bin\Release</OutputPath>
    <DefineConstants>TRACE;SILVERLIGHT;WINDOWS_PHONE</DefineConstants>
    <NoStdLib>true</NoStdLib>
    <NoConfig>true</NoConfig>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="System.Windows" />
    <Reference Include="system" />
    <Reference Include="System.Core" />
    <Reference Include="System.Xml" />
    <Reference Include="System.Net" />
    <Reference Include="WeborbPhoneClient">
      <SpecificVersion>False</SpecificVersion>
      <HintPath>WeborbPhoneClient.dll</HintPath>
    </Reference>   
  </ItemGroup>
  <ItemGroup>
    <Compile Include="Properties\AssemblyInfo.cs" />
    <xsl:for-each select="//service">
      <xsl:variable name="temp" select="translate(@fullname,'.','\')"/>
      <xsl:variable name="sourceFilePath" select="substring($temp,1,string-length($temp)-string-length(@name)-1)"/>
      <Compile Include="{$sourceFilePath}\{@name}Service.cs" />
      <Compile Include="{$sourceFilePath}\{@name}Model.cs" />
    </xsl:for-each>
    <xsl:for-each select="//datatype">
      <xsl:variable name="temp" select="translate(@fullname,'.','\')"/>
      <xsl:variable name="sourceFilePath" select="substring($temp,1,string-length($temp)-string-length(@name)-1)"/>
      <Compile Include="{$sourceFilePath}\Types\{@name}.cs" />
    </xsl:for-each>
    <xsl:for-each select="//enum">
      <xsl:variable name="temp" select="translate(@fullname,'.','\')"/>
      <xsl:variable name="sourceFilePath" select="substring($temp,1,string-length($temp)-string-length(@name)-1)"/>
      <Compile Include="{$sourceFilePath}\Types\{@name}.cs" />
    </xsl:for-each>
</ItemGroup>
<ItemGroup>
  <None Include="WeborbPhoneClient.dll" />
</ItemGroup>
  <Import Project="$(MSBuildExtensionsPath)\Microsoft\Silverlight for Phone\$(TargetFrameworkVersion)\Microsoft.Silverlight.$(TargetFrameworkProfile).Overrides.targets" />
  <Import Project="$(MSBuildExtensionsPath)\Microsoft\Silverlight for Phone\$(TargetFrameworkVersion)\Microsoft.Silverlight.CSharp.targets" />
  <ProjectExtensions />
  <!-- To modify your build process, add your task inside one of the targets below and uncomment it. 
       Other similar extension points exist, see Microsoft.Common.targets.
  <Target Name="BeforeBuild">
  </Target>
  <Target Name="AfterBuild">
  </Target>
  -->
</Project>
</file>
</xsl:template>

<!-- ********************************************************************************* -->
<!-- ****   Generates project file for the class library project which        ******** -->
<!-- ****   contains all the "plumbing" code generated from the backend svc   ******** -->
<!-- ********************************************************************************* -->
  <xsl:template name="codegen.sln.file.vs.wp7">
    <xsl:param name="projectName" />
    <xsl:param name="projectGuid"/>
<file name="{$projectName}.sln">Microsoft Visual Studio Solution File, Format Version 11.00
# Visual Studio 2010
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "InvokerApp", "InvokerDemoApp\InvokerApp.csproj", "{01C6E01F-7887-4598-AE7F-572B26EFF984}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "RemoteServiceLibrary", "RemoteServiceLibrary\RemoteServiceLibrary.csproj", "{<xsl:value-of select="$projectGuid" />}"
EndProject
Global
    GlobalSection(SolutionConfigurationPlatforms) = preSolution
        Debug|Any CPU = Debug|Any CPU
        Release|Any CPU = Release|Any CPU
    EndGlobalSection
    GlobalSection(ProjectConfigurationPlatforms) = postSolution
        {01C6E01F-7887-4598-AE7F-572B26EFF984}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
        {01C6E01F-7887-4598-AE7F-572B26EFF984}.Debug|Any CPU.Build.0 = Debug|Any CPU
        {01C6E01F-7887-4598-AE7F-572B26EFF984}.Debug|Any CPU.Deploy.0 = Debug|Any CPU
        {01C6E01F-7887-4598-AE7F-572B26EFF984}.Release|Any CPU.ActiveCfg = Release|Any CPU
        {01C6E01F-7887-4598-AE7F-572B26EFF984}.Release|Any CPU.Build.0 = Release|Any CPU
        {01C6E01F-7887-4598-AE7F-572B26EFF984}.Release|Any CPU.Deploy.0 = Release|Any CPU
        {<xsl:value-of select="$projectGuid" />}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
        {<xsl:value-of select="$projectGuid" />}.Debug|Any CPU.Build.0 = Debug|Any CPU
        {<xsl:value-of select="$projectGuid" />}.Release|Any CPU.ActiveCfg = Release|Any CPU
        {<xsl:value-of select="$projectGuid" />}.Release|Any CPU.Build.0 = Release|Any CPU
    EndGlobalSection
    GlobalSection(SolutionProperties) = preSolution
        HideSolutionNode = FALSE
    EndGlobalSection
EndGlobal
</file>
</xsl:template>
</xsl:stylesheet>