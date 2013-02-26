<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt">
	<xsl:template match="/">
		<folder name="weborb-codegen">
			<info>info text</info>
			<xsl:if test="data/fullCode = 'true'">
				<folder path="messagingDestinations/flex/.settings" hideContent="true"/>
				<folder path="messagingDestinations/flex/html-template" hideContent="true"/>
				<folder name="libs">
					<file path="../wdm/weborb.swc" hideContent="true" />
				</folder>
				<file name=".actionScriptProperties"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<actionScriptProperties mainApplicationPath="FlexExample.mxml" version="3">
<compiler additionalCompilerArguments="-services &quot;]]><xsl:value-of select="data/weborbPath"/><![CDATA[WEB-INF\flex\weborb-services-config.xml&quot; -locale en_US" copyDependentFiles="true" enableModuleDebug="true" generateAccessible="false" htmlExpressInstall="true" htmlGenerate="true" htmlHistoryManagement="true" htmlPlayerVersion="9.0.124" htmlPlayerVersionCheck="true" outputFolderLocation="]]><xsl:value-of select="data/weborbPath"/><![CDATA[examples\flex\messaging\codegen" outputFolderPath="bin-debug" rootURL="]]><xsl:value-of select="data/weborbRootURL"/><![CDATA[/examples/flex/messaging/codegen/" sourceFolderPath="src" strict="true" useApolloConfig="false" verifyDigests="true" warn="true">
<compilerSourcePath/>
<libraryPath defaultLinkType="1">
<libraryPathEntry kind="4" path=""/>
<libraryPathEntry kind="1" linkType="1" path="libs"/>
</libraryPath>
<sourceAttachmentPath/>
</compiler>
<applications>
<application path="FlexExample.mxml"/>
</applications>
<modules/>
<buildCSSFiles/>
</actionScriptProperties>
			]]></file>
				<file name=".flexProperties"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<flexProperties flexServerType="2" serverContextRoot="" serverRoot="]]><xsl:value-of select="data/weborbPath"/><![CDATA[" serverRootURL="]]><xsl:value-of select="data/weborbRootURL"/><![CDATA[" toolCompile="true" useServerFlexSDK="false" version="1"/>
				]]></file>
				<file name=".project"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
<projectDescription>
	<name>WeborbMessagingClient</name>
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
	<linkedResources>
	</linkedResources>
</projectDescription>
				]]></file>
				</xsl:if>
				<folder name="src">
					<file path="messagingDestinations/flex/FlexExample.mxml"/>
					<file name="FlexExample.as">
            <![CDATA[import mx.messaging.Consumer;
import mx.messaging.Producer;
import mx.messaging.events.MessageEvent;
import mx.messaging.messages.AsyncMessage;

private var consumer:Consumer = new Consumer();
private var producer:Producer = new Producer();
private var destination:String = "]]><xsl:value-of select="data/destinationId"/><![CDATA[";

private function init():void
{
	consumer.destination = destination;
	consumer.addEventListener(MessageEvent.MESSAGE, messageReceived);
	consumer.subscribe();
	
	producer = new Producer();
	producer.destination = destination;
}

private function messageReceived(event:MessageEvent):void
{
	var message:AsyncMessage = AsyncMessage(event.message);
	
	var sender:String = message.headers[ "WebORBClientId" ];
    
    if( sender == "" )
    	sender = "Anonymous";
	
	log.text += sender +" : "+ message.body + "\n";
}

private function onClick():void
{
	var message:AsyncMessage = new AsyncMessage();
	message.headers = {"WebORBClientId": clientIdField.text};
	message.body = messageField.text;
	producer.send(message); 
}
					]]></file>
				</folder>
		</folder>
	</xsl:template>
</xsl:stylesheet>