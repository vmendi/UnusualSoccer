<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
  xmlns:codegen="urn:cogegen-xslt-lib:xslt"
  xmlns:wdm="urn:schemas-themidnightcoders-com:xml-wdm"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="codegen.client.templates.xslt" />

  <xsl:template name="codegen.client">
    <file path="invokerapps/wdm-js/index.html" /> 
    <file path="invokerapps/wdm-js/style.css" />
    
    <folder name="jqgrid">
      <folder name="js" path="invokerapps/wdm-js/jqGrid/js/" />
      <folder name="css" path="invokerapps/wdm-js/jqGrid/css/" />
      <file name="wdm-model.js" override="true" >
        <xsl:call-template name="codegen.client.model" />
      </file>      
      <file path="invokerapps/wdm-js/jqGrid/index.html" /> 
      
      <!-- the following two files must come from weborbassets/wdm -->
      <file path="../scripts/WebORB.js" /> 
      <file path="../wdm/wdm.js" />
    </folder>
    
    <folder name="editablegrid">
      <folder name="js" path="invokerapps/wdm-js/EditableGrid/js/" />
      <folder name="css" path="invokerapps/wdm-js/EditableGrid/css/" />
      <file name="wdm-model.js" override="true" >
        <xsl:call-template name="codegen.client.model" />
      </file>
      <file path="invokerapps/wdm-js/EditableGrid/index.html" /> 
      
      <!-- the following two files must come from weborbassets/wdm -->
      <file path="../scripts/WebORB.js" /> 
      <file path="../wdm/wdm.js" />
    </folder>    
  </xsl:template>
</xsl:stylesheet>