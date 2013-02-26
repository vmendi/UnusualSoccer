<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt">
	<xsl:template match="/">
		<folder name="weborb-codegen">
			<info>info text</info>
				<folder name="libs">
					<file path="../wdm/weborb.swc"/>
				</folder>
				<file name=".actionScriptProperties"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<actionScriptProperties analytics="false" mainApplicationPath="CodeGenSample.mxml" projectUUID="366d4c61-1383-4661-ad62-274c1460fec8" version="6">
            <compiler additionalCompilerArguments="-locale en_US -services &quot;]]><xsl:value-of select="data/weborbPath"/><![CDATA[WEB-INF\flex\weborb-services-config.xml&quot;" autoRSLOrdering="false" copyDependentFiles="true" flexSDK="Flex 3.5" fteInMXComponents="false" generateAccessible="false" htmlExpressInstall="true" htmlGenerate="true" htmlHistoryManagement="true" htmlPlayerVersionCheck="true" includeNetmonSwc="false" outputFolderLocation="]]><xsl:value-of select="data/weborbPath"/><xsl:value-of select="data/applicationName"/>DemoApp" rootURL="<xsl:value-of select="data/weborbURL"/>/<xsl:value-of select="data/applicationName"/>DemoApp"<![CDATA[ outputFolderPath="bin-debug" sourceFolderPath="src" strict="true" targetPlayerVersion="0.0.0" useApolloConfig="false" useDebugRSLSwfs="true" verifyDigests="true" warn="true">
              <compilerSourcePath/>
              <libraryPath defaultLinkType="0">
                <libraryPathEntry kind="4" path="">
                  <excludedEntries>
                    <libraryPathEntry kind="3" linkType="1" path="${PROJECT_FRAMEWORKS}/libs/flex.swc" useDefaultLinkType="false"/>
                  </excludedEntries>
                </libraryPathEntry>
                <libraryPathEntry kind="1" linkType="1" path="libs"/>
              </libraryPath>
              <sourceAttachmentPath>
                <sourceAttachmentPathEntry kind="3" linkType="1" path="${PROJECT_FRAMEWORKS}/libs/datavisualization.swc" sourcepath="${PROJECT_FRAMEWORKS}/projects/datavisualization/src" useDefaultLinkType="false"/>
              </sourceAttachmentPath>
            </compiler>
            <applications>
              <application path="CodeGenSample.mxml"/>
              <application path="ui/broadcasting/watcher/BroadcastWatcherView.mxml"/>
            </applications>
            <modules/>
            <buildCSSFiles/>
          </actionScriptProperties>]]></file>
				<file path="messagingApplications/flex/.flexProperties"/>
				<file name=".project" type="xml" addxmlversion="true">
            <![CDATA[
<projectDescription>
	<name>]]><xsl:value-of select="data/applicationName"/>DemoApp<![CDATA[</name>
	<comment></comment>
	<projects>
	</projects>
	<buildSpec>
		<buildCommand>
			<name>com.adobe.flexbuilder.project.flexbuilder</name>
			<arguments>
			</arguments>
		</buildCommand>
	</buildSpec>
	<natures>
		<nature>com.adobe.flexbuilder.project.flexnature</nature>
		<nature>com.adobe.flexbuilder.project.actionscriptnature</nature>
	</natures>
</projectDescription>				
]]></file>
        <folder path="messagingApplications/flex/.settings"/>
        <folder path="messagingApplications/flex/html-template"/>
				<folder name="src">
					<file name="CodeGenSample.mxml" type="xml" addxmlversion="true">
            <![CDATA[
<mx:Application xmlns:mx="http://www.adobe.com/2006/mxml" 
	layout="absolute" minWidth="955" minHeight="600" 
	paddingLeft="20" paddingRight="20" paddingBottom="20" paddingTop="20" 
	]]>
	<xsl:for-each select="data/features/feature">
		<xsl:choose>
      <xsl:when test="id = 0">
        xmlns:bc="ui.broadcasting.*"
      </xsl:when>
      <xsl:when test="id = 1">
        xmlns:rec="ui.recording.*"
      </xsl:when>
      <xsl:when test="id = 2">
        xmlns:so="ui.sharedObj.*"
      </xsl:when>
      <xsl:when test="id = 3">
        xmlns:dp="ui.dataPush.*"
      </xsl:when>
      <xsl:when test="id = 4">
        xmlns:mc="ui.methodCall.*"
      </xsl:when>
		</xsl:choose>
	</xsl:for-each>
	<![CDATA[>	
	<mx:Accordion width="100%" height="100%" maxWidth="800" maxHeight="600" verticalCenter="0" horizontalCenter="0">]]>
    <xsl:for-each select="data/features/feature">
		<xsl:choose>
      <xsl:when test="id = 0">
        <![CDATA[<mx:Canvas label="Video Broadcast" width="100%" height="100%">
          <bc:VideoBroadcastView verticalCenter="0" horizontalCenter="0" />
        </mx:Canvas>]]>
      </xsl:when>
      <xsl:when test="id = 1">
        <![CDATA[<mx:Canvas label="Video Recording" width="100%" height="100%">
			<rec:VideoRecordingView verticalCenter="0" horizontalCenter="0" />
		</mx:Canvas>]]>
      </xsl:when>
      <xsl:when test="id = 2">
        <![CDATA[<mx:Canvas label="Remote Shared Object" width="100%" height="100%">
			<so:RemoteSharedObjectView verticalCenter="0" horizontalCenter="0" />
		</mx:Canvas>]]>
      </xsl:when>
      <xsl:when test="id = 3">
        <![CDATA[<mx:Canvas label="Data Push From Server" width="100%" height="100%">
			<dp:ServerDataPushView verticalCenter="0" horizontalCenter="0" />
		</mx:Canvas>]]>
      </xsl:when>
      <xsl:when test="id = 4">
        <![CDATA[<mx:Canvas label="Server Method Invocation" width="100%" height="100%">
			<mc:ServerMethodCallView verticalCenter="0" horizontalCenter="0" />
		</mx:Canvas>]]>
      </xsl:when>
		</xsl:choose>
	</xsl:for-each><![CDATA[		
	</mx:Accordion>
	
</mx:Application>]]></file>
          <folder name="ui">
            <file path="messagingApplications/flex/src/ui/Defaults.as"/>
            <xsl:for-each select="data/features/feature">
              <xsl:choose>
                <xsl:when test="id = 0">
                  <folder path="messagingApplications/flex/src/ui/broadcasting"/>
                </xsl:when>
                <xsl:when test="id = 1">
                  <folder path="messagingApplications/flex/src/ui/recording"/>
                </xsl:when>
                <xsl:when test="id = 2">
                  <folder path="messagingApplications/flex/src/ui/sharedObj"/>
                </xsl:when>
                <xsl:when test="id = 3">
                  <folder path="messagingApplications/flex/src/ui/dataPush"/>
                </xsl:when>
                <xsl:when test="id = 4">
                  <folder path="messagingApplications/flex/src/ui/methodCall"/>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>           
            <folder name="managers">
              <file name="ServiceManager.as">
package ui.managers
{
	import flash.net.NetConnection;

	import mx.messaging.config.ServerConfig;
	
  import mx.messaging.config.ServerConfig;
  import mx.rpc.AsyncToken;
  import mx.rpc.Responder;
  import mx.rpc.events.ResultEvent;
  import mx.rpc.remoting.RemoteObject;	

	/**
	* Helper class
	*/
	public class ServiceManager
	{
		/**
		* Gets connection string to the server
		*/
		public static function getUri():String
		{
			<xsl:for-each select="data/features/feature">
				<xsl:choose>
					<xsl:when test="id = 5 and included = 'true'">
			var uri:String = "rtmpt://localhost";
					</xsl:when>
					<xsl:when test="id = 5 and included != 'true'">
			var uri:String = ServerConfig.getChannel("weborb-rtmp").endpoint;
					</xsl:when>
				</xsl:choose>
			</xsl:for-each>

			uri += "/<xsl:value-of select="data/applicationName"/>";
			return uri;
		}
		
		public static function pingToWakeUp( callback:Function ):void
		{
			var remoteObject:RemoteObject = new RemoteObject( "WeborbManagement" );
			var asyncToken:AsyncToken = remoteObject.ping();

			asyncToken.addResponder( new Responder(
				function( evt:Object ):void
				{
					callback.apply();
				},

				function( evt:Object ):void
				{

				} ) );
		 }		
	}
}
              </file>
            </folder>
          </folder>
				</folder>
		</folder>
	</xsl:template>
</xsl:stylesheet>