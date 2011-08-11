<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt">
  <xsl:template match="/">
    <folder name="weborb-codegen">
      <info>info text</info>
          <file name="index.html"><![CDATA[<html>
  <head>
    <title>JavaScript code gereration exaple</title>
    <script language="javascript" src="WebORB.js"></script>
    <script language="javascript">    
      var myConsumer = new Consumer("]]><xsl:value-of select="data/destinationId"/><![CDATA[", new Async(messageReceived, handleFault));
      var myProducer = new Producer("]]><xsl:value-of select="data/destinationId"/><![CDATA[");

      webORB.defaultRemotingURL = "]]><xsl:value-of select="data/weborbURL"/><![CDATA[";
      
      function init()
      {
        myConsumer.subscribe();
      }
      
      function messageReceived(responseObj) 
      {
        var log = document.getElementById("log");
        var sender = responseObj.headers.WebORBClientId;
        
        if(!sender)
          sender = "Anonymous";
        
        log.value += sender +" : "+ responseObj.body + "\n";
      }
      
      function handleFault(responseObj)
      {
        log.value = "Error: " + responseObj + "\n";
      }
      
      function onClick()
      {
        var clientIdField = document.getElementById("clientIdField");
        var messageField = document.getElementById("messageField");
        var headers = {WebORBClientId:clientIdField.value};
        
        myProducer.send(messageField.value, undefined, undefined, headers);
      }
      
      function consoleLog(logMessage)
      {
        //alert(logMessage);
      }
      
    </script>
  </head>
  <body>
  Client id: <input type="text" id="clientIdField"/>
  <br/> 
  <br/>
  <textarea id="log" rows="20" cols="30"></textarea>
  <script language="javascript">
    init();
  </script>
  <br/>
  Message: <input type="text" id="messageField"/>
  <br/>
  <input type="button" value="Publish" onclick="onClick()" />
  </body>
</html>
          ]]></file>
          <file path="../scripts/WebORB.js" />
    </folder>
  </xsl:template>
</xsl:stylesheet>