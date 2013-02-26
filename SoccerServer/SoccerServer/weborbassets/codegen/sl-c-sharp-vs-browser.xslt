<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:fn="http://www.w3.org/2005/xpath-functions">
<xsl:template name="main-vs">
<xsl:param name="file-name" />
<xsl:param name="projectGuid" />     
  <folder name="VS2010">
  <folder name="InvokerDemoApp">
    <file path="../silverlight/WeborbClient.dll" hideContent="true"/>  
	<file path="invokerapps/moonlight/InvokerDemoApp/App.xaml" />
	<file path="invokerapps/moonlight/InvokerDemoApp/App.xaml.cs" />
	<file path="invokerapps/moonlight/InvokerDemoApp/Page.xaml" />
	<file path="invokerapps/moonlight/InvokerDemoApp/Page.xaml.cs" />
	<file path="invokerapps/moonlight/InvokerDemoApp/PageModel.cs" />
	<folder name="Properties">
	  <file path="invokerapps/silverlight/AppManifest.xml" />
	  <file path="invokerapps/silverlight/AssemblyInfo.cs" />
	</folder>
    <folder name="ViewModels">
      <file path="invokerapps/moonlight/InvokerDemoApp/ViewModels/ArgInfo.cs" />
      <file path="invokerapps/moonlight/InvokerDemoApp/ViewModels/ArrayInfo.cs" />
      <file path="invokerapps/moonlight/InvokerDemoApp/ViewModels/ComplexTypeInfo.cs" />
      <file path="invokerapps/moonlight/InvokerDemoApp/ViewModels/GenericInfo.cs" />
      <file path="invokerapps/moonlight/InvokerDemoApp/ViewModels/PageModel.cs" />
      <file path="invokerapps/moonlight/InvokerDemoApp/ViewModels/PrimitiveInfo.cs" />
    </folder>
	<xsl:call-template name="invokerdemoapp-csproj-vs">
	    <xsl:with-param name="file-name" select="$file-name"/>
	    <xsl:with-param name="projectGuid" select="$projectGuid"/>
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
    <xsl:call-template name="codegen.project.file.vs">
      <xsl:with-param name="file-name" select="$file-name"/>
      <xsl:with-param name="projectGuid" select="$projectGuid"/>
    </xsl:call-template>  
    <file path="../silverlight/WeborbClient.dll" hideContent="true"/>  
  </folder>
  <xsl:call-template name="codegen.sln.invokerdemoapp.web"/>
  <xsl:call-template name="codegen.sln.file.vs">
     <xsl:with-param name="projectName" select="$file-name"/>  
     <xsl:with-param name="projectGuid" select="$projectGuid"/>
  </xsl:call-template>  
 </folder>    
      
  <!--        
		<folder name="VS2010">
		  <xsl:call-template name="assembly-info">
		     <xsl:with-param name="file-name" select="$file-name"/>
		     <xsl:with-param name="projectGuid" select="$projectGuid"/>
		  </xsl:call-template>
		  <folder name="Bin">
		    <file path="../silverlight/WeborbClient.dll" hideContent="true"/>
		  </folder>
		  <xsl:for-each select="/namespaces">
		    <xsl:call-template name="codegen.process.namespace" />
		  </xsl:for-each>
		  <xsl:call-template name="codegen.project.file">
		     <xsl:with-param name="projectVersion" select="2010"/>
		     <xsl:with-param name="projectGuid" select="$projectGuid"/>
		   </xsl:call-template>
		</folder>    -->
    </xsl:template>
    
<!-- ********************************************************************************* -->
<!-- ****   .csproj file for the InvokerDemoApp project. The project let's  ********** -->
<!-- ****   users invoke methods of the selected service using SL client    ********** -->
<!-- ********************************************************************************* -->
<xsl:template name="invokerdemoapp-csproj-vs">
  <xsl:param name="file-name" />
  <xsl:param name="projectGuid" />
  <file name="InvokerDemoApp.csproj" type="xml">    
<Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProductVersion>8.0.50727</ProductVersion>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>{5D17EEBE-0C48-4C47-8747-DD9F712A0CAE}</ProjectGuid>
    <ProjectTypeGuids>{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{fae04ec0-301f-11d3-bf4b-00c04f79efbc}</ProjectTypeGuids>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace>Invoker</RootNamespace>
    <AssemblyName>InvokerDemoApp</AssemblyName>
    <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <SilverlightVersion>$(TargetFrameworkVersion)</SilverlightVersion>
    <SilverlightApplication>true</SilverlightApplication>
    <SupportedCultures>
    </SupportedCultures>
    <XapOutputs>true</XapOutputs>
    <GenerateSilverlightManifest>true</GenerateSilverlightManifest>
    <XapFilename>InvokerDemoApp.xap</XapFilename>
    <SilverlightManifestTemplate>Properties\AppManifest.xml</SilverlightManifestTemplate>
    <SilverlightAppEntry>Invoker.App</SilverlightAppEntry>
    <TestPageFileName>InvokerDemoAppTestPage.html</TestPageFileName>
    <CreateTestPage>true</CreateTestPage>
    <ValidateXaml>true</ValidateXaml>
    <EnableOutOfBrowser>false</EnableOutOfBrowser>
    <OutOfBrowserSettingsFile>Properties\OutOfBrowserSettings.xml</OutOfBrowserSettingsFile>
    <UsePlatformExtensions>false</UsePlatformExtensions>
    <ThrowErrorsInValidation>true</ThrowErrorsInValidation>
    <LinkedServerProject>
    </LinkedServerProject>
    <TargetFrameworkProfile />
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
    <Reference Include="system" />
    <Reference Include="System.Core" />
    <Reference Include="System.Net" />
    <Reference Include="System.Xml" />
    <Reference Include="System.Windows.Controls" />
    <Reference Include="System.Windows.Browser" />
    <Reference Include="WeborbClient">
      <SpecificVersion>False</SpecificVersion>
      <HintPath>WeborbClient.dll</HintPath>
    </Reference>      
  </ItemGroup>
  <ItemGroup>
    <Compile Include="App.xaml.cs">
      <DependentUpon>App.xaml</DependentUpon>
    </Compile>
    <Compile Include="Page.xaml.cs">
      <DependentUpon>Page.xaml</DependentUpon>
    </Compile>
    <Compile Include="Page.cs" />
    <Compile Include="Properties\AssemblyInfo.cs" />
    <Compile Include="ServiceModel.cs" />
    <Compile Include="ViewModels\ArgInfo.cs" />
    <Compile Include="ViewModels\ArrayInfo.cs" />
    <Compile Include="ViewModels\ComplexTypeInfo.cs" />
    <Compile Include="ViewModels\GenericInfo.cs" />
    <Compile Include="ViewModels\PageModel.cs" />
    <Compile Include="ViewModels\PrimitiveInfo.cs" />
  </ItemGroup>
  <ItemGroup>
    <ApplicationDefinition Include="App.xaml">
      <SubType>Designer</SubType>
      <Generator>MSBuild:Compile</Generator>
    </ApplicationDefinition>
    <Page Include="Page.xaml">
      <SubType>Designer</SubType>
      <Generator>MSBuild:Compile</Generator>
    </Page>
  </ItemGroup>
  <ItemGroup>
    <None Include="Properties\AppManifest.xml" />
  </ItemGroup>
  <ItemGroup>
    <ProjectReference Include="..\{$file-name}\{$file-name}.csproj">
      <Project>{<xsl:value-of select="$projectGuid"/>}</Project>
      <Name><xsl:value-of select="$file-name"/></Name>
    </ProjectReference>  
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

<!-- ********************************************************************************* -->
<!-- ****   Generates project file for the class library project which        ******** -->
<!-- ****   contains all the "plumbing" code generated from the backend svc   ******** -->
<!-- ********************************************************************************* -->

  <xsl:template name="codegen.project.file.vs">
    <xsl:param name="file-name"/>
    <xsl:param name="projectGuid"/>
    <file name="{$file-name}.csproj" type="xml" addxmlversion="true">
<Project ToolsVersion="4.0" DefaultTargets="Build" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <Configuration Condition=" '$(Configuration)' == '' ">Debug</Configuration>
    <Platform Condition=" '$(Platform)' == '' ">AnyCPU</Platform>
    <ProductVersion>8.0.50727</ProductVersion>
    <SchemaVersion>2.0</SchemaVersion>
    <ProjectGuid>{<xsl:value-of select="$projectGuid"/>}</ProjectGuid>
    <ProjectTypeGuids>{A1591282-1198-4647-A2B1-27E5FF5F6F3B};{fae04ec0-301f-11d3-bf4b-00c04f79efbc}</ProjectTypeGuids>
    <OutputType>Library</OutputType>
    <AppDesignerFolder>Properties</AppDesignerFolder>
    <RootNamespace><xsl:value-of select="$file-name"/></RootNamespace>
    <AssemblyName><xsl:value-of select="$file-name"/></AssemblyName>
    <TargetFrameworkIdentifier>Silverlight</TargetFrameworkIdentifier>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <SilverlightVersion>$(TargetFrameworkVersion)</SilverlightVersion>
    <SilverlightApplication>false</SilverlightApplication>
    <ValidateXaml>true</ValidateXaml>
    <ThrowErrorsInValidation>true</ThrowErrorsInValidation>
    <TargetFrameworkProfile />
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
    <Reference Include="system" />
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
    <VisualStudio>
      <FlavorProperties GUID="{A1591282-1198-4647-A2B1-27E5FF5F6F3B}">
        <SilverlightProjectProperties />
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

<!-- ********************************************************************************* -->
<!-- ****   Generates project file for the class library project which        ******** -->
<!-- ****   contains all the "plumbing" code generated from the backend svc   ******** -->
<!-- ********************************************************************************* -->
  <xsl:template name="codegen.sln.file.vs">
    <xsl:param name="projectName" />
    <xsl:param name="projectGuid"/>
<file name="{$projectName}.sln">Microsoft Visual Studio Solution File, Format Version 11.00
# Visual Studio 2010
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "InvokerDemoApp", "InvokerDemoApp\InvokerDemoApp.csproj", "{5D17EEBE-0C48-4C47-8747-DD9F712A0CAE}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "InvokerDemoApp.Web", "InvokerDemoApp.Web\InvokerDemoApp.Web.csproj", "{7285BAB0-D0B5-4CE2-BF1A-3312EBCE32CC}"
EndProject
Project("{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}") = "<xsl:value-of select="$projectName"/>", "<xsl:value-of select="$projectName"/>\<xsl:value-of select="$projectName"/>.csproj", "{<xsl:value-of select="$projectGuid"/>}"
EndProject
Global
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
		Debug|Any CPU = Debug|Any CPU
		Release|Any CPU = Release|Any CPU
	EndGlobalSection
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
		{5D17EEBE-0C48-4C47-8747-DD9F712A0CAE}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{5D17EEBE-0C48-4C47-8747-DD9F712A0CAE}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{5D17EEBE-0C48-4C47-8747-DD9F712A0CAE}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{5D17EEBE-0C48-4C47-8747-DD9F712A0CAE}.Release|Any CPU.Build.0 = Release|Any CPU
		{7285BAB0-D0B5-4CE2-BF1A-3312EBCE32CC}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{7285BAB0-D0B5-4CE2-BF1A-3312EBCE32CC}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{7285BAB0-D0B5-4CE2-BF1A-3312EBCE32CC}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{7285BAB0-D0B5-4CE2-BF1A-3312EBCE32CC}.Release|Any CPU.Build.0 = Release|Any CPU
		{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.ActiveCfg = Debug|Any CPU
		{<xsl:value-of select="$projectGuid"/>}.Debug|Any CPU.Build.0 = Debug|Any CPU
		{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.ActiveCfg = Release|Any CPU
		{<xsl:value-of select="$projectGuid"/>}.Release|Any CPU.Build.0 = Release|Any CPU
	EndGlobalSection
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
EndGlobal
</file>
</xsl:template>

<!-- ************************************************************************************* -->
<!-- ****   .Web project allowing the silverlight app to run as an http:// app    ******** -->
<!-- ************************************************************************************* -->
  <xsl:template name="codegen.sln.invokerdemoapp.web">
    <folder name="InvokerDemoApp.Web">
     <file path="invokerapps/silverlight/InvokerDemoApp/InvokerDemoApp.Web.csproj" />
     <file path="invokerapps/silverlight/InvokerDemoApp/InvokerDemoApp.Web.csproj.user" />        
     <file path="invokerapps/silverlight/InvokerDemoApp/InvokerDemoAppTestPage.aspx" />
     <file path="invokerapps/silverlight/InvokerDemoApp/InvokerDemoAppTestPage.html" />
     <file path="invokerapps/silverlight/InvokerDemoApp/Silverlight.js" />
     <file path="invokerapps/silverlight/InvokerDemoApp/Web.config" />
     <file path="invokerapps/silverlight/InvokerDemoApp/Web.Debug.config" />
     <file path="invokerapps/silverlight/InvokerDemoApp/Web.Release.config" />
     <folder name="Properties">
       <file path="invokerapps/silverlight/InvokerDemoApp/Properties/AssemblyInfo.cs" />
     </folder>
    </folder>
  </xsl:template>
</xsl:stylesheet>