<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">
<xsl:template name="main-mono">
    <xsl:param name="file-name" />
    <xsl:param name="projectGuid" />
  <folder name="MonoDevelop">
  <folder name="InvokerDemoApp">
    <file path="../silverlight/WeborbClient.dll" hideContent="true"/>  
	<file path="invokerapps/moonlight/InvokerDemoApp/App.xaml" />
	<file path="invokerapps/moonlight/InvokerDemoApp/App.xaml.cs" />
	<file path="invokerapps/moonlight/InvokerDemoApp/Page.xaml" />
	<file path="invokerapps/moonlight/InvokerDemoApp/Page.xaml.cs" />
	<file path="invokerapps/moonlight/InvokerDemoApp/PageModel.cs" />
	<xsl:call-template name="invokerdemoapp-csproj-mono">
	    <xsl:with-param name="file-name" select="$file-name"/>
	</xsl:call-template>
    <xsl:call-template name="service-model">
       <xsl:with-param name="file-name" select="$file-name"/>
    </xsl:call-template>	 
  </folder>
  <folder name="{$file-name}">
    <xsl:call-template name="assembly-info">
       <xsl:with-param name="file-name" select="$file-name"/>
       <xsl:with-param name="projectGuid" select="$projectGuid"/>
    </xsl:call-template>
    <xsl:for-each select="/namespaces">
      <xsl:call-template name="codegen.process.namespace" />
    </xsl:for-each>
    <xsl:call-template name="codegen.project.file.mono">
      <xsl:with-param name="file-name" select="$file-name"/>
      <xsl:with-param name="projectGuid" select="$projectGuid"/>
    </xsl:call-template>  
    <file path="../silverlight/WeborbClient.dll" hideContent="true"/>  
  </folder>
  <xsl:call-template name="codegen.sln.file.mono">
     <xsl:with-param name="projectName" select="$file-name"/>  
     <xsl:with-param name="projectGuid" select="$projectGuid"/>
  </xsl:call-template>
 </folder>
</xsl:template>


<!-- ********************************************************************************* -->
<!-- ****   .csproj file for the InvokerDemoApp project. The project let's  ********** -->
<!-- ****   users invoke methods of the selected service using SL client    ********** -->
<!-- ********************************************************************************* -->
<xsl:template name="invokerdemoapp-csproj-mono">
  <xsl:param name="file-name" />
  <file name="InvokerDemoApp.csproj" type="xml" addxmlversion="true">
<Project DefaultTargets="Build" ToolsVersion="3.5" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProductVersion>9.0.21022</ProductVersion>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>{B893C0D2-5E2C-4D5B-AF07-E1B3B5E3458E}</ProjectGuid>
    <ProjectTypeGuids>{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}</ProjectTypeGuids>
    <OutputType>Library</OutputType>
    <RootNamespace>Invoker</RootNamespace>
    <CreateTestPage>true</CreateTestPage>
    <SilverlightAppEntry>Invoker.App</SilverlightAppEntry>
    <ThrowErrorsInValidation>false</ThrowErrorsInValidation>
    <ValidateXaml>false</ValidateXaml>
    <XapOutputs>true</XapOutputs>
    <SilverlightApplication>true</SilverlightApplication>
    <XapFilename>Invoker.xap</XapFilename>
    <GenerateSilverlightManifest>true</GenerateSilverlightManifest>
    <AssemblyName>Invoker</AssemblyName>
    <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
    <TestPageFileName>InvokerDemoApp.html</TestPageFileName>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Debug|AnyCPU' ">
    <DebugSymbols>true</DebugSymbols>
    <DebugType>full</DebugType>
    <Optimize>false</Optimize>
    <OutputPath>bin\Debug</OutputPath>
    <DefineConstants>DEBUG</DefineConstants>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
    <ConsolePause>false</ConsolePause>
  </PropertyGroup>
  <PropertyGroup Condition=" '$(Configuration)|$(Platform)' == 'Release|AnyCPU' ">
    <DebugType>none</DebugType>
    <Optimize>false</Optimize>
    <OutputPath>bin\Release</OutputPath>
    <ErrorReport>prompt</ErrorReport>
    <WarningLevel>4</WarningLevel>
    <ConsolePause>false</ConsolePause>
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="System.Windows" />
    <Reference Include="mscorlib" />
    <Reference Include="System" />
    <Reference Include="System.Core" />
    <Reference Include="System.Xml" />
    <Reference Include="System.Net" />
    <Reference Include="System.Windows.Browser" />
    <Reference Include="WeborbClient">
      <SpecificVersion>False</SpecificVersion>
      <HintPath>WeborbClient.dll</HintPath>
    </Reference>    
  </ItemGroup>
  <ItemGroup>
    <ApplicationDefinition Include="App.xaml">
      <SubType>Designer</SubType>
      <Generator>MSBuild:MarkupCompilePass1</Generator>
    </ApplicationDefinition>
  </ItemGroup>
  <ItemGroup>
    <Compile Include="App.xaml.cs">
      <DependentUpon>App.xaml</DependentUpon>
    </Compile>
    <Compile Include="Page.xaml.cs">
      <DependentUpon>Page.xaml</DependentUpon>
    </Compile>
    <Compile Include="Page.cs" />
    <Compile Include="PageModel.cs" />
    <Compile Include="ServiceModel.cs" />
  </ItemGroup>
  <ItemGroup>
    <Page Include="Page.xaml">
      <SubType>Designer</SubType>
      <Generator>MSBuild:MarkupCompilePass1</Generator>
    </Page>
  </ItemGroup>
  <ItemGroup>
    <None Include="WeborbClient.dll" />
  </ItemGroup>  
  <Import Project="$(MSBuildBinPath)\Microsoft.CSharp.targets" />
  <Import Project="$(MSBuildExtensionsPath)\Microsoft\Silverlight\v2.0\Microsoft.Silverlight.CSharp.targets" />
  <ProjectExtensions>
    <MonoDevelop>
      <Properties InternalTargetFrameworkVersion="SL2.0" />
    </MonoDevelop>
  </ProjectExtensions>
  <ItemGroup>
    <ProjectReference Include="..\{$file-name}\{$file-name}.csproj">
      <Project>{6BFC2D79-BC91-4A8E-86AC-99179E431F8F}</Project>
      <Name><xsl:value-of select="$file-name"/></Name>
    </ProjectReference>
  </ItemGroup>
</Project>	
	</file>
</xsl:template>

<!-- ********************************************************************************* -->
<!-- ****   Generates project file for the class library project which        ******** -->
<!-- ****   contains all the "plumbing" code generated from the backend svc   ******** -->
<!-- ********************************************************************************* -->

  <xsl:template name="codegen.project.file.mono">
    <xsl:param name="file-name"/>
    <xsl:param name="projectGuid"/>
    <file name="{$file-name}.csproj" type="xml"  addxmlversion="true">
    <Project ToolsVersion="3.5" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
     <PropertyGroup>
      <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
      <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
      <ProductVersion>8.0.50727</ProductVersion>
      <SchemaVersion>2.0</SchemaVersion>
      <ProjectGuid>{<xsl:value-of select="$projectGuid"/>}</ProjectGuid>
      <ProjectTypeGuids>{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}</ProjectTypeGuids>
      <OutputType>Library</OutputType>
      <AppDesignerFolder>Properties</AppDesignerFolder>
      <RootNamespace><xsl:value-of select="$file-name"/></RootNamespace>
      <AssemblyName><xsl:value-of select="$file-name"/></AssemblyName>
      <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
      <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
      <SilverlightVersion>$(TargetFrameworkVersion)</SilverlightVersion>
      <SilverlightApplication>false</SilverlightApplication>
      <ValidateXaml>true</ValidateXaml>
      <ThrowErrorsInValidation>true</ThrowErrorsInValidation>
    </PropertyGroup>
    <!-- This property group is only here to support building this project using the 
         MSBuild 3.5 toolset. In order to work correctly with this older toolset, it needs 
         to set the TargetFrameworkVersion to v3.5 -->
    <PropertyGroup Condition="'$(MSBuildToolsVersion)' == '3.5'">
      <TargetFrameworkVersion>v3.5</TargetFrameworkVersion>
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
  </PropertyGroup>
  <ItemGroup>
    <Reference Include="mscorlib" />
    <Reference Include="System.Windows" />
    <Reference Include="System.Core" />
    <Reference Include="System.Xml" />
    <Reference Include="System.Net" />
    <Reference Include="System.Windows.Browser" />
    <Reference Include="System" />
    <Reference Include="System.Windows.Controls">
      <Package>moonlight-web-2.0-redist</Package>
    </Reference>  
    <Reference Include="WeborbClient">
      <SpecificVersion>False</SpecificVersion>
      <HintPath>WeborbClient.dll</HintPath>
    </Reference>
  </ItemGroup>
        <ItemGroup>
          <Compile Include="Properties\AssemblyInfo.cs" />
          <xsl:for-each select="//service">
            <xsl:variable name="temp" select="translate(@fullname,'.','\')"/>
            <xsl:variable name="sourceFilePath" select="substring($temp,1,string-length($temp)-string-length(@name)-1)"/>
            <Compile Include="{$sourceFilePath}\{@name}Service.cs" />
            <Compile Include="{$sourceFilePath}\I{@name}.cs" />
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
          <None Include="WeborbClient.dll" />
        </ItemGroup>
       <Import Project="$(MSBuildExtensionsPath32)\Microsoft\Silverlight\$(SilverlightVersion)\Microsoft.Silverlight.CSharp.targets" />
       <ProjectExtensions>
         <MonoDevelop>
           <Properties InternalTargetFrameworkVersion="SL2.0" xmlns="" />
         </MonoDevelop>
       </ProjectExtensions>
      </Project>     
    </file>
  </xsl:template>
  
<!-- ********************************************************************************* -->
<!-- ****   Generates solution file for the class library project which       ******** -->
<!-- ****   contains all the "plumbing" code generated from the backend svc   ******** -->
<!-- ********************************************************************************* -->
  
  <xsl:template name="codegen.sln.file.mono">
    <xsl:param name="projectName" />
    <xsl:param name="projectGuid"/>
<file name="{$projectName}.sln">Microsoft Visual Studio Solution File, Format Version 10.00
# Visual Studio 2008
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "InvokerDemoApp", "InvokerDemoApp\InvokerDemoApp.csproj", "{B893C0D2-5E2C-4D5B-AF07-E1B3B5E3458E}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "<xsl:value-of select="$projectName"/>", "<xsl:value-of select="$projectName"/>\<xsl:value-of select="$projectName"/>.csproj", "{<xsl:value-of select="$projectGuid"/>}"
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
		{B893C0D2-5E2C-4D5B-AF07-E1B3B5E3458E}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{B893C0D2-5E2C-4D5B-AF07-E1B3B5E3458E}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{B893C0D2-5E2C-4D5B-AF07-E1B3B5E3458E}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{B893C0D2-5E2C-4D5B-AF07-E1B3B5E3458E}.Release|Any CPU.Build.0 = Release|Any CPU		
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		StartupItem = InvokerDemoApp\InvokerDemoApp.csproj
		Policies = $0
		$0.TextStylePolicy = $1
		$1.inheritsSet = VisualStudio
		$1.inheritsScope = text/plain
		$1.scope = text/x-csharp
		$0.CSharpFormattingPolicy = $2
		$2.inheritsSet = Mono
		$2.inheritsScope = text/x-csharp
		$2.scope = text/x-csharp
	EndGlobalSection
EndGlobal
</file>
</xsl:template>  
</xsl:stylesheet>