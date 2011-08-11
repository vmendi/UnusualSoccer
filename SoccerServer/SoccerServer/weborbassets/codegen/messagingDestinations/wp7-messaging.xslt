<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">

  <xsl:template match="/">
    <xsl:param name="projectGuid" select="codegen:getGuid()"/>
    <folder name="weborb-codegen">
      <folder name="WindowsPhoneMessaging">
        <xsl:if test="data/fullCode = 'true'">
          <folder path="messagingDestinations\wp7\WindowsPhoneMessaging\Images" />
          <folder path="messagingDestinations\wp7\WindowsPhoneMessaging\Properties" />
          <folder name="Bin">
            <file path="../silverlight/windowsphone/WeborbPhoneClient.dll" hideContent="true"/>
          </folder>
        </xsl:if>
        <file path="messagingDestinations\wp7\WindowsPhoneMessaging\App.xaml.cs" />
        <file path="messagingDestinations\wp7\WindowsPhoneMessaging\App.xaml" />
        <file path="messagingDestinations\wp7\WindowsPhoneMessaging\MainPage.xaml" />
        <file path="messagingDestinations\wp7\WindowsPhoneMessaging\WebORBURLPage.xaml.cs" />
        <file path="messagingDestinations\wp7\WindowsPhoneMessaging\WebORBURLPage.xaml" />
        <xsl:call-template name="mainpage.file" />
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
    <file name="WindowsPhoneMessaging.csproj" type="xml">
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
          <RootNamespace>WindowsPhoneMessagingChat</RootNamespace>
          <AssemblyName>WindowsPhoneMessagingChat</AssemblyName>
          <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
          <SilverlightVersion>$(TargetFrameworkVersion)</SilverlightVersion>
          <TargetFrameworkProfile>WindowsPhone</TargetFrameworkProfile>
          <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
          <SilverlightApplication>true</SilverlightApplication>
          <SupportedCultures>
          </SupportedCultures>
          <XapOutputs>true</XapOutputs>
          <GenerateSilverlightManifest>true</GenerateSilverlightManifest>
          <XapFilename>WindowsPhoneMessagingChat.xap</XapFilename>
          <SilverlightManifestTemplate>Properties\AppManifest.xml</SilverlightManifestTemplate>
          <SilverlightAppEntry>WindowsPhoneMessagingChat.App</SilverlightAppEntry>
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
          <Reference Include="Microsoft.Phone" />
          <Reference Include="Microsoft.Phone.Interop" />
          <Reference Include="System.Windows" />
          <Reference Include="system" />
          <Reference Include="System.Core" />
          <Reference Include="System.Net" />
          <Reference Include="System.Xml" />
          <Reference Include="WeborbPhoneClient">
            <HintPath>Bin\WeborbPhoneClient.dll</HintPath>
          </Reference>
        </ItemGroup>
        <ItemGroup>
          <Compile Include="App.xaml.cs">
            <DependentUpon>App.xaml</DependentUpon>
          </Compile>
          <Compile Include="MainPage.xaml.cs">
            <DependentUpon>MainPage.xaml</DependentUpon>
          </Compile>
          <Compile Include="Properties\AssemblyInfo.cs" />
          <Compile Include="WebORBURLPage.xaml.cs">
            <DependentUpon>WebORBURLPage.xaml</DependentUpon>
          </Compile>
        </ItemGroup>
        <ItemGroup>
          <ApplicationDefinition Include="App.xaml">
            <SubType>Designer</SubType>
            <Generator>MSBuild:Compile</Generator>
          </ApplicationDefinition>
          <Page Include="MainPage.xaml">
            <SubType>Designer</SubType>
            <Generator>MSBuild:Compile</Generator>
          </Page>
          <Page Include="WebORBURLPage.xaml">
            <Generator>MSBuild:Compile</Generator>
            <SubType>Designer</SubType>
          </Page>
        </ItemGroup>
        <ItemGroup>
          <None Include="Properties\AppManifest.xml" />
          <None Include="Properties\WMAppManifest.xml" />
        </ItemGroup>
        <ItemGroup>
          <Content Include="Images\ApplicationIcon.png">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
          </Content>
          <Content Include="Images\Background.png">
            <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
          </Content>
          <Content Include="Images\appbar.feature.settings.rest.png" />
          <Content Include="Images\SplashScreenImage.jpg" />
        </ItemGroup>
        <Import Project="$(MSBuildExtensionsPath)\Microsoft\Silverlight for Phone\$(TargetFrameworkVersion)\Microsoft.Silverlight.$(TargetFrameworkProfile).Overrides.targets" />
        <Import Project="$(MSBuildExtensionsPath)\Microsoft\Silverlight for Phone\$(TargetFrameworkVersion)\Microsoft.Silverlight.CSharp.targets" />
        <!-- To modify your build process, add your task inside one of the targets below and uncomment it. 
       Other similar extension points exist, see Microsoft.Common.targets.
  <Target Name="BeforeBuild">
  </Target>
  <Target Name="AfterBuild">
  </Target>
  -->
        <ProjectExtensions />
      </Project>
    </file>
  </xsl:template>
  <xsl:template name="sln.file">
    <xsl:param name="projectGuid"/>
    <file name="WindowsPhoneMessaging.sln">Microsoft Visual Studio Solution File, Format Version 11.00
# Visual Studio 2010
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "WindowsPhoneMessaging", "WindowsPhoneMessaging\WindowsPhoneMessaging.csproj", "{<xsl:value-of select="$projectGuid"/>}"
EndProject
Global
GlobalSection(SolutionConfigurationPlatforms) = preSolution
Debug|Any CPU = Debug|Any CPU
Release|Any CPU = Release|Any CPU
EndGlobalSection
GlobalSection(ProjectConfigurationPlatforms) = postSolution
{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.Build.0 = Debug|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.Deploy.0 = Debug|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.ActiveCfg = Release|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.Build.0 = Release|Any CPU
{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.Deploy.0 = Release|Any CPU
EndGlobalSection
GlobalSection(SolutionProperties) = preSolution
HideSolutionNode = FALSE
EndGlobalSection
EndGlobal
    </file>
  </xsl:template>
  <xsl:template name="mainpage.file">
    <file name="MainPage.xaml.cs">using System;
using System.Collections.Generic;
using System.Windows;
using Microsoft.Phone.Controls;
using Weborb.Client;
using Weborb.Types;
using Weborb.V3Types;

namespace WindowsPhoneMessagingChat
{
  public partial class MainPage : PhoneApplicationPage
  {
    public static string WeborbUrl = "<xsl:value-of select="data/weborbURL"/>"; // Can also change to "rtmpt://localhost/root";
    private WeborbClient _client;

    public MainPage()
    {
      InitializeComponent();
      Init();
    }

    private void Init()
    {
      _client = new WeborbClient( MainPage.WeborbUrl, "<xsl:value-of select="data/destinationId"/>" );
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
      asyncMessage.headers = new Dictionary&lt;object, object> {{"WebORBClientId", ClientId.Text}};
      asyncMessage.body = Message.Text;
      _client.Publish(asyncMessage);
    }

    private void ApplicationBarMenuItem_Click( object sender, EventArgs e )
    {
      NavigationService.Navigate( new Uri( "/WebORBURLPage.xaml", UriKind.Relative ) );
    }
  }
}
    </file>
  </xsl:template>
</xsl:stylesheet>
