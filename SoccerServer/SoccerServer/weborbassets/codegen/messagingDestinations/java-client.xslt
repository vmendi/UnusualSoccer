<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:codegen="urn:cogegen-xslt-lib:xslt">
	<xsl:template match="/">
<folder name="weborb-codegen">
<folder name="eclipse">
  <file path="messagingDestinations/java/.project"/>
  <file name=".classpath"><![CDATA[<?xml version="1.0" encoding="UTF-8"?>
  <classpath>
    <classpathentry kind="src" path="src"/>
    <classpathentry kind="con" path="org.eclipse.jdt.launching.JRE_CONTAINER"/>
    <classpathentry kind="lib" path="lib/weborbclient.jar" /> 
    <classpathentry kind="output" path="bin"/>
  </classpath>
  ]]></file>
  <xsl:call-template name="sourcecodefile" />
  <folder name="lib">
    <file path="../javaclient/weborbclient.jar" />
  </folder>
</folder>
<folder name="idea">
  <file path="messagingDestinations/java/idea/WeborbMessagingClient.iml"/>
  <folder name=".idea" path="messagingDestinations/java/idea/.idea" />
  <xsl:call-template name="sourcecodefile" />
  <folder name="lib">
    <file path="../javaclient/weborbclient.jar" />
  </folder>
</folder>
</folder>
</xsl:template>
<xsl:template name="sourcecodefile">
  <folder name="src">
    <folder name="examples">
      <folder name="weborb">
<file name="ClientExample.java"><![CDATA[package examples.weborb;

import java.util.Scanner;

import weborb.client.Fault;
import weborb.client.IResponder;
import weborb.client.WeborbClient;
import weborb.exceptions.MessageException;
import weborb.reader.StringType;
import weborb.v3types.AsyncMessage;

public class ClientExample implements IResponder
{
  public static void main( String[] args ) throws Exception
  {
    WeborbClient client = new WeborbClient("]]><xsl:value-of select="data/weborbURL"/><![CDATA[", "]]><xsl:value-of select="data/destinationId"/><![CDATA[", "Java Client" );
    IResponder listener = new ClientExample();
    client.subscribe( listener );

    String input = null;
    Scanner scanner = new Scanner( System.in );

    while( !"exit".equals( input ) )
    {
      System.out.print( "Type a message and press [Enter] to send it or 'exit' to quit\n> " );
      input = scanner.nextLine();
      if( input != null && !input.isEmpty() )
        try
        {
          client.publish( input );
        }
        catch( Exception e )
        {
          e.printStackTrace( System.out );
        }
    }
  }

  public void errorHandler( Fault fault ) throws MessageException
  {
    System.out.println( "Error: " + fault.getMessage() + "\n" + fault.getDetail() + "\n" );
  }

  public void responseHandler( Object adaptedObject ) throws MessageException
  {
    for( Object message : (Object[]) adaptedObject )
    {
      if( message instanceof AsyncMessage )
      {
        AsyncMessage asyncMessage = (AsyncMessage) message;

        for( Object body : (Object[]) asyncMessage.body.body )
          if( body instanceof StringType )
          {
            String sender = (String) asyncMessage.headers.get( "WebORBClientId" );

            if( sender == null )
              sender = "Anonymous";

            System.out.println( "Received message from '" + sender + "' : " + ((StringType) body).defaultAdapt() );
          }
      }
    }
  }
}
]]></file>
      </folder>
    </folder>
  </folder>
</xsl:template>
</xsl:stylesheet>