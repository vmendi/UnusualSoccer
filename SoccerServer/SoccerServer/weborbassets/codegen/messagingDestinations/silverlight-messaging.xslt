<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">

  <xsl:template match="/">
    <xsl:param name="projectGuid" select="codegen:getGuid()"/>
    <xsl:param name="webProjectGuid" select="codegen:getGuid()"/>
    <folder name="weborb-codegen">
      <xsl:if test="data/fullCode = 'true'">
        <folder name="SilverlightMessaging.Web">
          <folder path="messagingDestinations\silverlight\SilverlightMessaging.Web\Properties" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging.Web\Silverlight.js" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging.Web\SilverlightMessagingTestPage.aspx" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging.Web\SilverlightMessagingTestPage.html" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging.Web\Web.config" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging.Web\Web.Debug.config" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging.Web\Web.Release.config" />
          <xsl:call-template name="web.project.file">
            <xsl:with-param name="webProjectGuid" select="$webProjectGuid"/>
          </xsl:call-template>
        </folder>
      </xsl:if>
      <folder name="SilverlightMessaging">
        <xsl:if test="data/fullCode = 'true'">
          <folder path="messagingDestinations\silverlight\SilverlightMessaging\Properties" />
          <folder name="Bin">
            <file path="../silverlight/WeborbClient.dll" hideContent="true"/>
          </folder>
          <file path="messagingDestinations\silverlight\SilverlightMessaging\App.xaml.cs" />
          <file path="messagingDestinations\silverlight\SilverlightMessaging\App.xaml" />
        </xsl:if>        
        <file path="messagingDestinations\silverlight\SilverlightMessaging\Page.xaml" />
        <xsl:call-template name="page.file" />
        <xsl:if test="data/fullCode = 'true'">
          <xsl:call-template name="project.file">
            <xsl:with-param name="projectGuid" select="$projectGuid"/>
          </xsl:call-template>
        </xsl:if>
      </folder>
      <xsl:if test="data/fullCode = 'true'">
        <xsl:call-template name="sln.file">
          <xsl:with-param name="projectGuid" select="$projectGuid"/>
        </xsl:call-template>
      </xsl:if>
    </folder>
  </xsl:template>
  
  <xsl:template name="project.file">
    <xsl:param name="projectGuid"/>    
    <file name="SilverlightMessaging.csproj" type="xml">
      <Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
        <PropertyGroup Condition="'$(MSBuildToolsVersion)' == '3.5'">
          <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
        </PropertyGroup>
        <PropertyGroup>
          <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
          <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
          <ProductVersion>8.0.50727</ProductVersion>
          <SchemaVersion>2.0</SchemaVersion>
          <ProjectGuid>{<xsl:value-of select="$projectGuid"/>}</ProjectGuid>
          <ProjectTypeGuids>{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{fae04ec0-301f-11d3-bf4b-00c04f79efbc}</ProjectTypeGuids>
          <OutputType>Library</OutputType>
          <AppDesignerFolder>Properties</AppDesignerFolder>
          <RootNamespace>SilverlightMessaging</RootNamespace>
          <AssemblyName>SilverlightMessaging</AssemblyName>
          <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
          <SilverlightApplication>true</SilverlightApplication>
          <SupportedCultures>
          </SupportedCultures>
          <XapOutputs>true</XapOutputs>
          <GenerateSilverlightManifest>true</GenerateSilverlightManifest>
          <XapFilename>SilverlightMessaging.xap</XapFilename>
          <SilverlightManifestTemplate>Properties\AppManifest.xml</SilverlightManifestTemplate>
          <SilverlightAppEntry>SilverlightMessaging.App</SilverlightAppEntry>
          <TestPageFileName>TestPage.html</TestPageFileName>
          <CreateTestPage>true</CreateTestPage>
          <ValidateXaml>true</ValidateXaml>
          <ThrowErrorsInValidation>false</ThrowErrorsInValidation>
          <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
          <SilverlightVersion>$(TargetFrameworkVersion)</SilverlightVersion>
          <FileUpgradeFlags>
          </FileUpgradeFlags>
          <OldToolsVersion>3.5</OldToolsVersion>
          <UpgradeBackupLocation />
          <PublishUrl>publish\</PublishUrl>
          <Install>true</Install>
          <InstallFrom>Disk</InstallFrom>
          <UpdateEnabled>false</UpdateEnabled>
          <UpdateMode>Foreground</UpdateMode>
          <UpdateInterval>7</UpdateInterval>
          <UpdateIntervalUnits>Days</UpdateIntervalUnits>
          <UpdatePeriodically>false</UpdatePeriodically>
          <UpdateRequired>false</UpdateRequired>
          <MapFileExtensions>true</MapFileExtensions>
          <ApplicationRevision>0</ApplicationRevision>
          <ApplicationVersion>1.0.0.%2a</ApplicationVersion>
          <IsWebBootstrapper>false</IsWebBootstrapper>
          <UseApplicationTrust>false</UseApplicationTrust>
          <BootstrapperEnabled>true</BootstrapperEnabled>
        </PropertyGroup>
        <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
          <DebugSymbols>true</DebugSymbols>
          <DebugType>full</DebugType>
          <Optimize>false</Optimize>
          <OutputPath>Bin\Debug</OutputPath>
          <DefineConstants>DEBUG;TRACE;SILVERLIGHT</DefineConstants>
          <NoStdLib>true</NoStdLib>
          <NoConfig>true</NoConfig>
          <ErrorReport>prompt</ErrorReport>
          <WarningLevel>4</WarningLevel>
          <CodeAnalysisRuleSet>AllRules.ruleset</CodeAnalysisRuleSet>
        </PropertyGroup>
        <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
          <DebugType>pdbonly</DebugType>
          <Optimize>true</Optimize>
          <OutputPath>Bin\Release</OutputPath>
          <DefineConstants>TRACE;SILVERLIGHT</DefineConstants>
          <NoStdLib>true</NoStdLib>
          <NoConfig>true</NoConfig>
          <ErrorReport>prompt</ErrorReport>
          <WarningLevel>4</WarningLevel>
          <CodeAnalysisRuleSet>AllRules.ruleset</CodeAnalysisRuleSet>
        </PropertyGroup>
        <ItemGroup>
          <Reference Include="System.Windows" />
          <Reference Include="mscorlib" />
          <Reference Include="system" />
          <Reference Include="System.Core" />
          <Reference Include="System.Net" />
          <Reference Include="System.Xml" />
          <Reference Include="System.Windows.Browser" />
          <Reference Include="WeborbClient">
            <HintPath>Bin\WeborbClient.dll</HintPath>
          </Reference>
        </ItemGroup>
        <ItemGroup>
          <Compile Include="App.xaml.cs">
            <DependentUpon>App.xaml</DependentUpon>
          </Compile>
          <Compile Include="Page.xaml.cs">
            <DependentUpon>Page.xaml</DependentUpon>
          </Compile>
          <Compile Include="Properties\AssemblyInfo.cs" />
        </ItemGroup>
        <ItemGroup>
          <ApplicationDefinition Include="App.xaml">
            <Generator>MSBuild:MarkupCompilePass1</Generator>
            <Generator>MSBuild:Compile</Generator>
            <SubType>Designer</SubType>
          </ApplicationDefinition>
          <Page Include="Page.xaml">
            <Generator>MSBuild:MarkupCompilePass1</Generator>
            <Generator>MSBuild:Compile</Generator>
            <SubType>Designer</SubType>
          </Page>
        </ItemGroup>
        <ItemGroup>
          <None Include="Properties\AppManifest.xml" />
        </ItemGroup>
        <ItemGroup>
          <BootstrapperPackage Include="Microsoft.Net.Client.3.5">
            <Visible>False</Visible>
            <ProductName>.NET Framework 3.5 SP1 Client Profile</ProductName>
            <Install>false</Install>
          </BootstrapperPackage>
          <BootstrapperPackage Include="Microsoft.Net.Framework.3.5.SP1">
            <Visible>False</Visible>
            <ProductName>.NET Framework 3.5 SP1</ProductName>
            <Install>false</Install>
          </BootstrapperPackage>
        </ItemGroup>
        <Import Project="$(MSBuildExtensionsPath32)\Microsoft\Silverlight\$(SilverlightVersion)\Microsoft.Silverlight.CSharp.targets" />
        <!-- To modify your build process, add your task inside one of the targets below and uncomment it. 
       Other similar extension points exist, see Microsoft.Common.targets.
  <Target Name="BeforeBuild">
  </Target>
  <Target Name="AfterBuild">
  </Target>
  -->
        <ProjectExtensions>
          <VisualStudio>
            <FlavorProperties GUID="{A1591282-1198-4647-A2B1-27E5FF5F6F3B}">
              <SilverlightProjectProperties />
            </FlavorProperties>
          </VisualStudio>
        </ProjectExtensions>
      </Project>    
    </file>
  </xsl:template>
  <xsl:template name="web.project.file">
    <xsl:param name="webProjectGuid"/>
    <file name="SilverlightMessaging.Web.csproj" type="xml">
      <Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
        <PropertyGroup>
          <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
          <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
          <ProductVersion>
          </ProductVersion>
          <SchemaVersion>2.0</SchemaVersion>
          <ProjectGuid>{<xsl:value-of select="$webProjectGuid"/>}</ProjectGuid>
          <ProjectTypeGuids>{349c5851-65df-11da-9384-00065b846f21};{fae04ec0-301f-11d3-bf4b-00c04f79efbc}</ProjectTypeGuids>
          <OutputType>Library</OutputType>
          <AppDesignerFolder>Properties</AppDesignerFolder>
          <RootNamespace>SilverlightMessaging.Web</RootNamespace>
          <AssemblyName>SilverlightMessaging.Web</AssemblyName>
          <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
          <SilverlightApplicationList>{548CC11B-6B36-4C8E-805E-CD68C8522FEE}|..\SilverlightMessaging\SilverlightMessaging.csproj|ClientBin|False</SilverlightApplicationList>
        </PropertyGroup>
        <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
          <DebugSymbols>true</DebugSymbols>
          <DebugType>full</DebugType>
          <Optimize>false</Optimize>
          <OutputPath>bin\</OutputPath>
          <DefineConstants>DEBUG;TRACE</DefineConstants>
          <ErrorReport>prompt</ErrorReport>
          <WarningLevel>4</WarningLevel>
        </PropertyGroup>
        <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
          <DebugType>pdbonly</DebugType>
          <Optimize>true</Optimize>
          <OutputPath>bin\</OutputPath>
          <DefineConstants>TRACE</DefineConstants>
          <ErrorReport>prompt</ErrorReport>
          <WarningLevel>4</WarningLevel>
        </PropertyGroup>
        <ItemGroup>
          <Reference Include="Microsoft.CSharp" />
          <Reference Include="System.Web.DynamicData" />
          <Reference Include="System.Web.Entity" />
          <Reference Include="System.Web.ApplicationServices" />
          <Reference Include="System" />
          <Reference Include="System.Data" />
          <Reference Include="System.Core" />
          <Reference Include="System.Data.DataSetExtensions" />
          <Reference Include="System.Web.Extensions" />
          <Reference Include="System.Xml.Linq" />
          <Reference Include="System.Drawing" />
          <Reference Include="System.Web" />
          <Reference Include="System.Xml" />
          <Reference Include="System.Configuration" />
          <Reference Include="System.Web.Services" />
          <Reference Include="System.EnterpriseServices" />
        </ItemGroup>
        <ItemGroup>
          <Content Include="ClientBin\SilverlightMessaging.xap" />
          <Content Include="Silverlight.js" />
          <Content Include="SilverlightMessagingTestPage.aspx" />
          <Content Include="SilverlightMessagingTestPage.html" />
          <Content Include="Web.config" />
          <Content Include="Web.Debug.config">
            <DependentUpon>Web.config</DependentUpon>
          </Content>
          <Content Include="Web.Release.config">
            <DependentUpon>Web.config</DependentUpon>
          </Content>
        </ItemGroup>
        <ItemGroup>
          <Compile Include="Properties\AssemblyInfo.cs" />
        </ItemGroup>
        <ItemGroup />
        <Import Project="$(MSBuildBinPath)\Microsoft.CSharp.targets" />
        <Import Project="$(MSBuildExtensionsPath32)\Microsoft\VisualStudio\v10.0\WebApplications\Microsoft.WebApplication.targets" />
        <ProjectExtensions>
          <VisualStudio>
            <FlavorProperties GUID="{A1591282-1198-4647-A2B1-27E5FF5F6F3B}">
              <WebProjectProperties>
                <UseIIS>False</UseIIS>
                <AutoAssignPort>True</AutoAssignPort>
                <DevelopmentServerPort>19452</DevelopmentServerPort>
                <DevelopmentServerVPath>/</DevelopmentServerVPath>
                <IISUrl>
                </IISUrl>
                <NTLMAuthentication>False</NTLMAuthentication>
                <UseCustomServer>False</UseCustomServer>
                <CustomServerUrl>
                </CustomServerUrl>
                <SaveServerSettingsInUserFile>False</SaveServerSettingsInUserFile>
              </WebProjectProperties>
            </FlavorProperties>
          </VisualStudio>
        </ProjectExtensions>
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
  <xsl:template name="sln.file">
    <xsl:param name="projectGuid"/>
    <xsl:param name="webProjectGuid"/>
    <file name="SilverlightMessaging.sln">Microsoft Visual Studio Solution File, Format Version 11.00
# Visual Studio 2010
Project("{00000000-0000-0000-0000-000000000000}") = "SilverlightMessaging", "SilverlightMessaging\SilverlightMessaging.csproj", "{<xsl:value-of select="$projectGuid"/>}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "SilverlightMessaging.Web", "SilverlightMessaging.Web\SilverlightMessaging.Web.csproj", "{<xsl:value-of select="$webProjectGuid"/>}"
EndProject
Global
GlobalSection(SolutionConfigurationPlatforms) = preSolution
Debug|Any CPU = Debug|Any CPU
Release|Any CPU = Release|Any CPU
EndGlobalSection
GlobalSection(ProjectConfigurationPlatforms) = postSolution
{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.Build.0 = Debug|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.ActiveCfg = Release|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.Build.0 = Release|Any CPU
{<xsl:value-of select="$webProjectGuid"/>}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
{<xsl:value-of select="$webProjectGuid"/>}.Debug|Any CPU.Build.0 = Debug|Any CPU
{<xsl:value-of select="$webProjectGuid"/>}.Release|Any CPU.ActiveCfg = Release|Any CPU
{<xsl:value-of select="$webProjectGuid"/>}.Release|Any CPU.Build.0 = Release|Any CPU
EndGlobalSection
GlobalSection(SolutionProperties) = preSolution
HideSolutionNode = FALSE
EndGlobalSection
EndGlobal
    </file>
  </xsl:template>
  <xsl:template name="page.file">
    <file name="Page.xaml.cs">
      using System;
      using System.Collections.Generic;
      using System.IO;
      using System.Linq;
      using System.Net;
      using System.Security;
      using System.Windows;
      using System.Windows.Controls;
      using System.Windows.Documents;
      using System.Windows.Input;
      using System.Windows.Media;
      using System.Windows.Media.Animation;
      using System.Windows.Shapes;

      using Weborb.Client;
      using Weborb.Types;
      using Weborb.V3Types;

      namespace SilverlightMessaging
      {
      public partial class Page : UserControl
      {
      public Page()
      {
      InitializeComponent();
      weborburlTextbox.Text = _webORBUrl;
      }

      private WeborbClient _client;
      private String _webORBUrl = "<xsl:value-of select="data/weborbURL"/>"; // Can also change to "rtmpt://localhost/root";

      private void Init()
      {
      _client = new WeborbClient(_webORBUrl, "<xsl:value-of select="data/destinationId"/>");
      _client.Subscribed += () => Dispatcher.BeginInvoke(() => SendButton.IsEnabled = true);
      _client.Subscribe(
      new SubscribeResponder(
      message => Dispatcher.BeginInvoke(() =>
      {
      IAdaptingType[] body = message.GetBody();
      object mess = body[0].defaultAdapt();
      string sender = message.headers["WebORBClientId"].ToString() == ""
      ? "Anonymous"
      : message.headers["WebORBClientId"].ToString();
      Messages.Text += sender + ": " + mess + "\n";
      }),
      fault => Dispatcher.BeginInvoke(() => Messages.Text += fault.Message + "\n")));
      }

      private void SendButton_Click( object sender, RoutedEventArgs e )
      {
      AsyncMessage asyncMessage = new AsyncMessage();
      asyncMessage.headers = new Dictionary&lt;object, object> { { "WebORBClientId", ClientId.Text } };
      asyncMessage.body = Message.Text;
      _client.Publish( asyncMessage );
    }

    #region ConfigUrl
    private bool _accepted;

    private void ShowConfigButton_Click( object sender, RoutedEventArgs e )
    {
      ConfigPopup.IsOpen = true;
    }

    private void TestConnectionButton_Click( object sender, RoutedEventArgs e )
    {
      _accepted = false;
      TestConnection();
    }

    private void AcceptButton_Click( object sender, RoutedEventArgs e )
    {
      _accepted = true;
      TestConnection();
    }

    private void TestConnection()
    {
      EnabledUi( false );
      try
      {
        var url = weborburlTextbox.Text;
        var contentType = "application/x-amf";

        if ( url.StartsWith( "rtmpt" ) )
        {
          contentType = "application/x-fcs";
          url = GetUrl( url, "rtmpt://" );
        }
        if ( url.StartsWith( "rtmp" ) )
        {
          contentType = "application/x-fcs";
          url = GetUrl( url, "rtmp://" );
        }
        else
        {
          url = url.Replace( "weborb.aspx", "weborb.aspx?diag" );
        }

        HttpWebRequest request = (HttpWebRequest)WebRequest.Create( url );
        request.Method = "POST";
        request.ContentType = contentType;
        request.BeginGetRequestStream( new AsyncCallback( HandleURLCheck ), request );
      }
      catch ( Exception exception )
      {
        Deployment.Current.Dispatcher.BeginInvoke( new Action( () => MessageBox.Show( exception.Message, "Error", MessageBoxButton.OK ) ) );
        EnabledUi( true );
      }
    }

    private string GetUrl( string gateway, string protocol )
    {
      string url = gateway.Substring( protocol.Length, gateway.Length - ( protocol.Length ) );
      var host = "";
      var port = 80;

      int hostSeparatorPos = url.IndexOf( "/" );
      if ( hostSeparatorPos != -1 )
      {
        host = url.Substring( 0, hostSeparatorPos );
      }

      int portSeparatorPos = host.IndexOf( ":" );
      if ( portSeparatorPos != -1 )
      {
        port = int.Parse( host.Substring( portSeparatorPos + 1, host.Length - portSeparatorPos - 1 ) );
        host = host.Substring( 0, portSeparatorPos );
      }

      return String.Format( "http://{0}:{1}/open/1", host, protocol == "rtmp://" ? 80 : port );
    }

    private void HandleURLCheck( IAsyncResult asyncResult )
    {
      try
      {
        var bytesToSend = new byte[] { 0 };
        HttpWebRequest httpRequest = (HttpWebRequest)asyncResult.AsyncState;
        Stream postDataWriter = httpRequest.EndGetRequestStream( asyncResult );
        postDataWriter.Write( bytesToSend, 0, bytesToSend.Length );
        postDataWriter.Flush();
        postDataWriter.Close();

        httpRequest.BeginGetResponse( RequestResponseHandler, httpRequest );
      }
      catch ( Exception exception )
      {
        Deployment.Current.Dispatcher.BeginInvoke( new Action( () => MessageBox.Show( exception.Message, "Error", MessageBoxButton.OK ) ) );
      }
    }

    private void RequestResponseHandler( IAsyncResult asyncResult )
    {
      try
      {
        HttpWebRequest httpRequest = (HttpWebRequest)asyncResult.AsyncState;
        HttpWebResponse response = (HttpWebResponse)httpRequest.EndGetResponse( asyncResult );
        if ( response.StatusCode != HttpStatusCode.OK )
          throw new Exception( "Invalid URL" );
        if ( _accepted )
        {
          _accepted = false;
          Dispatcher.BeginInvoke( () =>
          {_webORBUrl = weborburlTextbox.Text;
            ConfigPopup.IsOpen = false;
            if ( _client != null &amp;&amp; _client.RTMP != null )
              _client.RTMP.disconnect();
            Init();

          } );
        }
        else
        {
          Deployment.Current.Dispatcher.BeginInvoke(
            new Action( () => MessageBox.Show( "WebORB URL is valid", "Success", MessageBoxButton.OK ) ) );
        }
      }
      catch ( Exception exception )
      {
        var message = exception.InnerException != null &amp;&amp; exception.InnerException is SecurityException
                        ? "Unable to connect to the server. Make sure clientaccesspolicy.xml are deployed in the root of the web server the client will communicate with."
                        : exception.Message;
        Deployment.Current.Dispatcher.BeginInvoke( new Action( () => MessageBox.Show( "Invalid URL. " + message, "Error", MessageBoxButton.OK ) ) );
      }
      finally
      {
        Dispatcher.BeginInvoke( () => EnabledUi( true ) );
      }
    }

    private void EnabledUi( bool enabled )
    {
      weborburlTextbox.IsEnabled = enabled;
      AcceptButton.IsEnabled = enabled;
      TestConnectionButton.IsEnabled = enabled;
    }
    #endregion

  }
}

    </file>
  </xsl:template>
</xsl:stylesheet>
