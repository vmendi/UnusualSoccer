<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" 
  xmlns:codegen="urn:cogegen-xslt-lib:xslt"
  xmlns:wdm="urn:schemas-themidnightcoders-com:xml-wdm"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">


  <!-- ==========================  CODEGEN.CLIENT.MODEL -->
  <xsl:template name="codegen.client.model">
    <xsl:for-each select="/xs:schema/runtime">
      <xsl:if test="position() = 1">
var __clientId__ = guid();
var webOrbURL = "<xsl:value-of select="@weborbRootURL" />/weborb.aspx?clientid=" + __clientId__;
</xsl:if>
    </xsl:for-each>

      <xsl:for-each select="/xs:schema/xs:element">
        <xsl:value-of select="codegen:setCurrentDatabase(@name)" />

        <xsl:call-template name="codegen.client.database.codegen" />
        <xsl:call-template name="codegen.client.datamapperregistry.codegen" />

        <xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='table']">
          <xsl:call-template name="codegen.client.datamapper.codegen" />
          <xsl:call-template name="codegen.client.domain.codegen" />
        </xsl:for-each>

      </xsl:for-each>




//	USER CLASSES
      <xsl:for-each select="/xs:schema/xs:element">
        <xsl:value-of select="codegen:setCurrentDatabase(@name)" />

        <xsl:call-template name="codegen.client.database" />
        <xsl:call-template name="codegen.client.datamapperregistry" />

        <xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='table']">
          <xsl:call-template name="codegen.client.datamapper" />
          <xsl:call-template name="codegen.client.domain" />
        </xsl:for-each>

        <xsl:call-template name="codegen.client.activerecords" />



//  INIT
        <xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='table']">
          <xsl:call-template name="codegen.client.init" />
        </xsl:for-each>

      </xsl:for-each>

  </xsl:template>

  
  
  
  
  <!-- ==========================  CODEGEN.CLIENT.DATABASE.CODEGEN -->
  <xsl:template name="codegen.client.database.codegen">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
//	================================================	_<xsl:value-of select="$class-name"/>Db
function _<xsl:value-of select="$class-name"/>Db()
{
    Database.call( this );
}
Utils.setInheritance( _<xsl:value-of select="$class-name"/>Db, Database );

_<xsl:value-of select="$class-name"/>Db.prototype.getRemoteClassName = function()
{
    return "<xsl:value-of select="codegen:getServerNamespace()" />.<xsl:value-of select="$class-name"/>Db";
}
<xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='storedprocedure']">
<xsl:variable name="storedProcedure" select="@name" />
_<xsl:value-of select="$class-name"/>Db.prototype.<xsl:value-of select="codegen:getStoredProcedureName(@name)"/> = function( <xsl:for-each select="xs:complexType/xs:attribute"><xsl:value-of select="codegen:getStoredProcedureParameter($storedProcedure,@name)" /><xsl:if test="position() != last()">, </xsl:if></xsl:for-each> )
{
    var remoteObject = this._createRemoteObject();
    var async = new Async();
    remoteObject.<xsl:value-of select="codegen:getStoredProcedureName(@name)"/>( <xsl:for-each select="xs:complexType/xs:attribute"><xsl:value-of select="codegen:getStoredProcedureParameter($storedProcedure,@name)" />, </xsl:for-each>async );
    return async;
}</xsl:for-each>
//	endof _<xsl:value-of select="$class-name"/>Db class

</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.DATAMAPPERREGISTRY.CODEGEN -->
  <xsl:template name="codegen.client.datamapperregistry.codegen">
//	================================================	_DataMapperRegistry
function _DataMapperRegistry()
{<xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='table']">
    this._<xsl:value-of select="codegen:getFunctionParameter(@name)"/>DataMapper = null;</xsl:for-each>
}
<xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='table']">
  <xsl:variable name="class-name" select="codegen:getClassName(@name)" />

_DataMapperRegistry.prototype.get<xsl:value-of select="$class-name"/> = function()
{
    if( this._<xsl:value-of select="codegen:getFunctionParameter(@name)"/>DataMapper == null )
        this._<xsl:value-of select="codegen:getFunctionParameter(@name)"/>DataMapper = new <xsl:value-of select="$class-name"/>DataMapper();

    return this._<xsl:value-of select="codegen:getFunctionParameter(@name)"/>DataMapper;
}</xsl:for-each>
//	endof _DataMapperRegistry class

</xsl:template>

  
  <!-- ==========================  CODEGEN.CLIENT.DATAMAPPER.CODEGEN -->
  <xsl:template name="codegen.client.datamapper.codegen">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
    <xsl:variable name="id" select="@id"   />
    <xsl:variable name="pk" select="xs:key/@name" />
    <xsl:variable name="table" select="@name"   />
//	================================================	_<xsl:value-of select="$class-name"/>DataMapper
function _<xsl:value-of select="$class-name"/>DataMapper()
{
    DataMapper.call( this );
}
Utils.setInheritance( _<xsl:value-of select="$class-name"/>DataMapper, DataMapper );

_<xsl:value-of select="$class-name"/>DataMapper.prototype.getRemoteClassName = function()
{
    return "<xsl:value-of select="codegen:getServerNamespace()" />.<xsl:value-of select="$class-name"/>DataMapper";
}

_<xsl:value-of select="$class-name"/>DataMapper.prototype.createActiveRecordInstance = function()
{
    return new <xsl:value-of select="$class-name"/>();
}

_<xsl:value-of select="$class-name"/>DataMapper.prototype.getDatabase = function()
{
    return <xsl:value-of select="codegen:getClassName(../../../@name)" />Db.Instance;
}

_<xsl:value-of select="$class-name"/>DataMapper.prototype.load = function( <xsl:value-of select="codegen:getFunctionParameter($class-name)" />, async )
{
    if( !<xsl:value-of select="codegen:getFunctionParameter($class-name)" />.isPrimaryKeyInitialized() )
        throw "Record can be loaded only with initialized primary key.";

    if( IdentityMap.global.exists( <xsl:value-of select="codegen:getFunctionParameter($class-name)" />.getURI() ) )
    {
        <xsl:value-of select="codegen:getFunctionParameter($class-name)" /> = IdentityMap.global.extract( <xsl:value-of select="codegen:getFunctionParameter($class-name)" />.getURI() );

        if( <xsl:value-of select="codegen:getFunctionParameter($class-name)" />.getIsLoaded() || <xsl:value-of select="codegen:getFunctionParameter($class-name)" />.getIsLoading() )
            return <xsl:value-of select="codegen:getFunctionParameter($class-name)" />;
    }

    <xsl:value-of select="codegen:getFunctionParameter($class-name)" />.setIsLoading( true );

    if( async == null )
    {
        <xsl:value-of select="codegen:getFunctionParameter($class-name)" /> = this._createRemoteObject().findByPrimaryKey( <xsl:for-each select="xs:key/xs:field"><xsl:value-of select="codegen:getFunctionParameter($class-name)" />.<xsl:value-of select="codegen:getPropertyName($table,substring(@xpath,2))"/><xsl:if test="position() != last()">, </xsl:if></xsl:for-each> );
        <xsl:value-of select="codegen:getFunctionParameter($class-name)" />.setIsLoaded( true );
    }
    else
        this._createRemoteObject().findByPrimaryKey( <xsl:for-each select="xs:key/xs:field"><xsl:value-of select="codegen:getFunctionParameter($class-name)" />.<xsl:value-of select="codegen:getPropertyName($table,substring(@xpath,2))"/><xsl:if test="position() != last()">, </xsl:if></xsl:for-each>, DatabaseAsync.wrapAsync( async, <xsl:value-of select="codegen:getFunctionParameter($class-name)" /> ) );

    IdentityMap.global.add( <xsl:value-of select="codegen:getFunctionParameter($class-name)" /> );
    return <xsl:value-of select="codegen:getFunctionParameter($class-name)" />;
}

_<xsl:value-of select="$class-name"/>DataMapper.prototype.findByPrimaryKey = function( <xsl:for-each select="xs:complexType/xs:attribute[concat('@',@name) = key('pk',$table)/@xpath]"><xsl:value-of select="codegen:getFunctionParameter(@name)" /><xsl:if test="position() != last()">, </xsl:if></xsl:for-each> )
{
    var activeRecord = new <xsl:value-of select="$class-name"/>();
    <xsl:for-each select="xs:key/xs:field">activeRecord.<xsl:value-of select="codegen:getPropertyName($table,substring(@xpath,2))"/> = <xsl:value-of select="codegen:getFunctionParameter(substring(@xpath,2))"/>;
    </xsl:for-each>
    return this.load( activeRecord );
}

_<xsl:value-of select="$class-name"/>DataMapper.prototype.loadChildRelation = function( activeRecord, relationName, activeCollection )
{<xsl:for-each select="key('dependent',current()/xs:key/@name)">
  <xsl:variable name="child-table" select="@name" />
  <xsl:variable name="child-table-pk" select="xs:key/@name" />
  <xsl:for-each select="xs:keyref[@refer = $pk]">
    <xsl:variable name="fk" select="@name" />
    <xsl:for-each select="key('table',$child-table-pk)">
      <xsl:choose>
        <xsl:when test="count(xs:key/xs:field[@xpath = key('fkByName',$fk)/@xpath]) = count(xs:key/xs:field)">
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="hidden-property" select="codegen:getChildProperty($table,@name,$fk,1)" />
          <xsl:variable name="dynamic-function">findBy( "<xsl:for-each select="key('fkByName',$fk)">
              <xsl:if test="position() != 1">And</xsl:if>
              <xsl:value-of select="codegen:getStoredProcedureName(substring(@xpath,2))"/>
            </xsl:for-each>", <xsl:for-each select="key('pkByElementId',$id)">
              <xsl:if test="position() != 1">, </xsl:if>activeRecord.<xsl:value-of select="codegen:getPropertyName(../../@name,substring(@xpath,2))"/>
            </xsl:for-each>, activeCollection, this._getRelationQueryOptions( relationName ) )</xsl:variable>
    if( relationName == "<xsl:value-of select="$hidden-property" />" )
    {
      DataMapperRegistry.Instance.get<xsl:value-of select="codegen:getClassName(@name)" />().<xsl:value-of select="$dynamic-function" />;
      return;
    }</xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </xsl:for-each>
</xsl:for-each>
}
//	endof _<xsl:value-of select="$class-name"/>DataMapper class

</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.DOMAIN.CODEGEN -->
  <xsl:template name="codegen.client.domain.codegen">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
    <xsl:variable name="id" select="@id"   />
    <xsl:variable name="pk" select="xs:key/@name" />
    <xsl:variable name="table" select="@name"   />
//	================================================	_<xsl:value-of select="$class-name"/>
function _<xsl:value-of select="$class-name"/>( <!--xsl:for-each select="xs:complexType/xs:attribute[not(concat('@',@name) = key('fk',$class-name)/@xpath)]"--><xsl:for-each select="xs:complexType/xs:attribute"><xsl:value-of select="codegen:getFunctionParameter(codegen:getPropertyName($table,@name))" /><xsl:if test="position() != last()">, </xsl:if></xsl:for-each> )
{
    ActiveRecord.call( this );
<xsl:for-each select="xs:complexType/xs:attribute">
      <xsl:variable name="property" select="codegen:getPropertyName($table,@name)" />
      <!--xsl:if test="not(concat('@',@name) = key('fkByElementId',$id)/@xpath)"-->
        <xsl:choose>
          <xsl:when test="not(../../xs:key/xs:field[@xpath = concat('@',current()/@name)])">
    this.<xsl:value-of select="$property"/> = <xsl:value-of select="codegen:getFunctionParameter($property)"/>;</xsl:when>
          <xsl:otherwise>
    this.<xsl:value-of select="$property"/> = <xsl:value-of select="codegen:getFunctionParameter($property)"/> || <xsl:value-of select="codegen:getDefaultJsTypeValue(@type)"/>;</xsl:otherwise>
        </xsl:choose>
      <!--/xsl:if-->
    </xsl:for-each>

    <!--xsl:for-each select="xs:keyref">
    this._<xsl:value-of select="codegen:getParentProperty($table, key('table',@refer)/@name, @name,1)" /><xsl:if test="xs:field[substring(@xpath,2) = ../../xs:complexType/xs:attribute[@use='required']/@name]"> = new <xsl:value-of select="codegen:getClassName(key('table',@refer)/@name)"/>()</xsl:if>;</xsl:for-each-->
    
    this._originalProperties = 
    { 
        <xsl:for-each select="xs:complexType/xs:attribute">
        <xsl:variable name="property" select="codegen:getPropertyName($table,@name)" />
        <!--xsl:if test="not(concat('@',@name) = key('fkByElementId',$id)/@xpath)"-->
        <xsl:value-of select="$property"/>: <xsl:value-of select="codegen:getFunctionParameter($property)"/><xsl:if test="position() != last()">, 
        </xsl:if>
        <!--/xsl:if-->
    </xsl:for-each> 
    };
    
    this._columnsInfo = 
    [<xsl:for-each select="xs:complexType/xs:attribute">
      new ColumnInfo( "<xsl:value-of select="codegen:getPropertyName($table,@name)"/>", "<xsl:value-of select="codegen:getJSDataType(@type)" />", <xsl:choose><xsl:when test="../../xs:key/xs:field[@xpath = concat('@',current()/@name)]">true</xsl:when><xsl:otherwise>false</xsl:otherwise></xsl:choose>, <xsl:choose><xsl:when test="@use = 'required'">true</xsl:when><xsl:otherwise>false</xsl:otherwise></xsl:choose> )<xsl:if test="position() != last()">, </xsl:if>
    </xsl:for-each> 
    ];
    <xsl:for-each select="key('dependent',current()/xs:key/@name)">
    <xsl:variable name="child-table" select="@name" />
    <xsl:variable name="child-table-pk" select="xs:key/@name" />
    <xsl:for-each select="xs:keyref[@refer = $pk]">
      <xsl:variable name="fk" select="@name" />
      <xsl:for-each select="key('table',$child-table-pk)">
        <xsl:choose>
          <xsl:when test="count(xs:key/xs:field[@xpath = key('fkByName',$fk)/@xpath]) = count(xs:key/xs:field)">
    // one to one relation
    this._<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)" /> = null;
          </xsl:when>
          <xsl:otherwise>
    // one to many relation
    this._<xsl:value-of select="codegen:getChildProperty($table,@name,$fk,1)" /> = new ActiveCollection();
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:for-each>
}
Utils.setInheritance( _<xsl:value-of select="$class-name"/>, ActiveRecord );

<xsl:for-each select="xs:keyref">
    <xsl:variable name="key" select="@name" />
    <xsl:variable name="parent-table" select="key('table',@refer)/@name" />
    <xsl:variable name="parent-class" select="codegen:getClassName($parent-table)" />
    <xsl:variable name="var-name" select="concat('_',codegen:getParentProperty($table,$parent-table,$key,1))" />
    <xsl:variable name="var-name-s" select="codegen:getParentProperty($table,$parent-table,$key,1)" />
_<xsl:value-of select="$class-name"/>.prototype.get<xsl:value-of select="codegen:getParentProperty($table, $parent-table, $key,0)" /> = function()
{
    var <xsl:value-of select="$var-name-s" /> = new <xsl:value-of select="$parent-class" />();
    <xsl:value-of select="$var-name-s" />.<xsl:value-of select="substring(../../xs:element/xs:key[@name = current()/@refer][1]/xs:field[1]/@xpath, 2)" /> = this.<xsl:value-of select="substring(xs:field[1]/@xpath, 2)" />;
    
    return DataMapperRegistry.Instance.get<xsl:value-of select="$parent-class"/>().load( <xsl:value-of select="$var-name-s" /> );
}
<!--
_<xsl:value-of select="$class-name"/>.prototype.get<xsl:value-of select="codegen:getParentProperty($table, $parent-table, $key,0)" /> = function()
{
    if( this._isLazyLoadingEnabled() &amp;&amp; <xsl:if test="not(xs:field[substring(@xpath,2) = ../../xs:complexType/xs:attribute[@use='required']/@name])"><xsl:value-of select="$var-name" /> &amp;&amp; </xsl:if>!( this.<xsl:value-of select="$var-name" />.getIsLoaded() || this.<xsl:value-of select="$var-name" />.getIsLoading() ) )
    {
        var oldValue = this.<xsl:value-of select="$var-name" />;
        this.<xsl:value-of select="$var-name" /> = DataMapperRegistry.Instance.<xsl:value-of select="$parent-class"/>.load( this.<xsl:value-of select="$var-name" /> );
        if( oldValue != this.<xsl:value-of select="$var-name" /> )
            this._onParentChanged( oldValue, this.<xsl:value-of select="$var-name" /> );
    }

    return this.<xsl:value-of select="$var-name" />;
}

_<xsl:value-of select="$class-name"/>.prototype.set<xsl:value-of select="codegen:getParentProperty($table, $parent-table, $key,0)" /> = function( value )
{
    if( value != null )
    {
        var oldValue = this.<xsl:value-of select="$var-name" />;
        this.<xsl:value-of select="$var-name" /> = IdentityMap.global.register( value );

        if( oldValue != this.<xsl:value-of select="$var-name" /> )
            this._onParentChanged( oldValue, this.<xsl:value-of select="$var-name" /> );
    }
    else
        this.<xsl:value-of select="$var-name" /> = null;
}
-->
</xsl:for-each>

<xsl:for-each select="key('dependent',current()/xs:key/@name)">
    <xsl:variable name="child-table" select="@name" />
    <xsl:variable name="child-table-pk" select="xs:key/@name" />

    <xsl:for-each select="xs:keyref[@refer = $pk]">
      <xsl:variable name="fk" select="@name" />
      <xsl:for-each select="key('table',$child-table-pk)">
        <xsl:choose>
          <xsl:when test="count(xs:key/xs:field[@xpath = key('fkByName',$fk)/@xpath]) = count(xs:key/xs:field)">
            <xsl:variable name="var-name" select="concat('_',codegen:getChildProperty($table,$child-table,$fk,1))" />
// one to one relation
_<xsl:value-of select="$class-name"/>.prototype.get<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,0)" /> = function()
{
    if( this._isLazyLoadingEnabled() <![CDATA[&&]]> <xsl:value-of select="$var-name" /> == null )
    {
        this.<xsl:value-of select="$var-name" /> = DataMapperRegistry.Instance.get<xsl:value-of select="codegen:getClassName(@name)" />().findByPrimaryKey( <xsl:for-each select="key('pkByName',$pk)"><xsl:if test="position() != 1">, </xsl:if>this.<xsl:value-of select="codegen:getPropertyName($table, substring(@xpath,2))"/></xsl:for-each> );
        this.<xsl:value-of select="$var-name" />._related<xsl:value-of select="$class-name" /> = this;
    }

    return this.<xsl:value-of select="$var-name" />;
}

_<xsl:value-of select="$class-name"/>.prototype.set<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,0)" /> = function( value )
{
      this.<xsl:value-of select="$var-name" /> = value;
      this.<xsl:value-of select="$var-name" />._related<xsl:value-of select="$class-name" /> = this;
}</xsl:when>
      <xsl:otherwise>
        <xsl:variable name="var-name" select="concat('_',codegen:getChildProperty($table,@name,$fk,1))" />
        <xsl:variable name="hidden-property" select="codegen:getChildProperty($table,@name,$fk,1)" />
// one to many relation
_<xsl:value-of select="$class-name"/>.prototype.get<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,0)" /> = function()
{
    this.<xsl:value-of select="$var-name" /> = this._onChildRelationRequest( "<xsl:value-of select="$hidden-property" />", this.<xsl:value-of select="$var-name" /> );
    return this.<xsl:value-of select="$var-name" />;
}</xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
  </xsl:for-each>

_<xsl:value-of select="$class-name"/>.prototype.isPrimaryKeyInitialized = function()
{
    return <xsl:for-each select="xs:complexType/xs:attribute">
      <xsl:variable name="property" select="codegen:getPropertyName($table,@name)" />
      <xsl:if test="not(concat('@',@name) = key('fkByElementId',$id)/@xpath)">
        <xsl:choose>
          <xsl:when test="../../xs:key/xs:field[@xpath = concat('@',current()/@name)]">
            <xsl:if test="position() != 1">
        &amp;&amp; </xsl:if>this.<xsl:value-of select="$property"/> != null &amp;&amp; this.<xsl:value-of select="$property"/>.toString().length > 0</xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:for-each>;
}

_<xsl:value-of select="$class-name"/>.prototype.getDataMapper = function()
{
    return DataMapperRegistry.Instance.get<xsl:value-of select="$class-name"/>();
}

_<xsl:value-of select="$class-name"/>.prototype.getURI = function()
{
    return "<xsl:value-of select="../../../@name"/>.<xsl:value-of select="@name"/>" 
        <xsl:for-each select="xs:key/xs:field">+ "." + this.<xsl:value-of select="codegen:getPropertyName($table,substring(@xpath,2))" />.toString()</xsl:for-each>;
}

_<xsl:value-of select="$class-name"/>.prototype.applyFields = function( object )
{
    try
    {
        this.disableLazyLoading();
  <xsl:for-each select="xs:complexType/xs:attribute">
    <xsl:variable name="property" select="codegen:getPropertyName($table,@name)" />
    <xsl:if test="../../xs:key/xs:field[@xpath != concat('@',current()/@name)]">
        this.<xsl:value-of select="$property"/> = object.<xsl:value-of select="$property"/>;</xsl:if>
  </xsl:for-each>
        
        this.clearIsDirty();
    }
    finally
    {
        this.enableLazyLoading();
    }
}

_<xsl:value-of select="$class-name"/>.prototype.prepareToSend = function( identityMap, cascade )
{
    var realRecord = identityMap.exists( this.ActiveRecordUID )? identityMap.extract( this.ActiveRecordUID ) : this;
    
    var activeRecord = new <xsl:value-of select="$class-name"/>();
    activeRecord.ActiveRecordUID = realRecord.ActiveRecordUID;
    <!--xsl:for-each select="xs:keyref">
      <xsl:variable name="property" select="codegen:getParentProperty($table, key('table',@refer)/@name, @name,1)" />
    activeRecord._<xsl:value-of select="$property"/> = 
        this._<xsl:value-of select="codegen:getParentProperty($table, key('table',@refer)/@name, @name,1)" />.prepareToSend( identityMap, false );</xsl:for-each-->
    
    <!-- xsl:for-each select="xs:complexType/xs:attribute[not(concat('@',@name) = key('fk',$class-name)/@xpath)]" -->
    <xsl:for-each select="xs:complexType/xs:attribute">
<xsl:variable name="property" select="codegen:getPropertyName($table,@name)" />
    activeRecord.<xsl:value-of select="$property"/> = realRecord.<xsl:value-of select="$property"/>;</xsl:for-each>
    <xsl:if test="key('dependent',current()/xs:key/@name)">
<!--    
    var refForRelated = new <xsl:value-of select="$class-name"/>();
    refForRelated.ActiveRecordUID = activeRecord.ActiveRecordUID;<xsl:for-each select="xs:complexType/xs:attribute">
      <xsl:variable name="pkName" select="codegen:getPropertyName($table,@name)" />
      <xsl:if test="../../xs:key/xs:field[@xpath = concat('@',current()/@name)]">
    refForRelated.<xsl:value-of select="$pkName"/> = activeRecord.<xsl:value-of select="$pkName"/>;</xsl:if>
    </xsl:for-each>
    refForRelated = refForRelated._getPublicObject();-->
      <xsl:for-each select="key('dependent',current()/xs:key/@name)">
        <xsl:variable name="child-table" select="@name" />
        <xsl:variable name="child-table-pk" select="xs:key/@name" />
        <xsl:for-each select="xs:keyref[@refer = $pk]">
          <xsl:variable name="fk" select="@name" />
          <xsl:variable name="child-var" select="concat(codegen:getFunctionParameter($child-table),position())" />
          <xsl:for-each select="key('table',$child-table-pk)">
            <xsl:choose>
              <xsl:when test="count(xs:key/xs:field[@xpath = key('fkByName',$fk)/@xpath]) = count(xs:key/xs:field)">
    
    if( realRecord.<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/> != null )
    {
        activeRecord.<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/> = realRecord.<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/>.prepareToSend( identityMap, true );
        activeRecord.<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/>.<xsl:value-of select="codegen:getParentProperty($child-table,$table,$fk,0)" /> = activeRecord;<!--refForRelated;-->
    }</xsl:when>
              <xsl:otherwise>
    
    if ( cascade &amp;&amp; ( realRecord._<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/> instanceof Collection ) &amp;&amp; realRecord._<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/>.getLength() > 0 )
    {
        realRecord._<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/>.forEach( function(<xsl:value-of select="$child-var" />)
        {
            if( <xsl:value-of select="$child-var" />.getIsDirty() )
            {
                var <xsl:value-of select="$child-var" />Extract = <xsl:value-of select="$child-var" />.prepareToSend( identityMap, true );
                <xsl:value-of select="$child-var" />Extract.<xsl:value-of select="codegen:getParentProperty($child-table,$table,$fk,0)" /> = activeRecord;<!--refForRelated;-->
                
                activeRecord.get<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,0)"/>().addItem( <xsl:value-of select="$child-var" />Extract );
            }
        } );
        
        activeRecord.<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,1)"/> = activeRecord.get<xsl:value-of select="codegen:getChildProperty($table,$child-table,$fk,0)"/>().getArray();
    }</xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:if>
    
    return activeRecord._getPublicObject();
}
<xsl:if test="key('dependent',current()/xs:key/@name)">
_<xsl:value-of select="$class-name"/>.prototype.extractChilds = function()
{
  	var childs = [];
  <xsl:for-each select="key('dependent',current()/xs:key/@name)">
    <xsl:variable name="child-table" select="@name" />
    <xsl:variable name="child-table-pk" select="xs:key/@name" />
    <xsl:for-each select="xs:keyref[@refer = $pk]">
      <xsl:variable name="fk" select="@name" />
      <xsl:variable name="child-var" select="concat(codegen:getFunctionParameter($child-table),position())" />

      <xsl:for-each select="key('table',$child-table-pk)">
        <xsl:choose>
          <xsl:when test="count(xs:key/xs:field[@xpath = key('fkByName',$fk)/@xpath]) = count(xs:key/xs:field)"></xsl:when>
          <xsl:otherwise>
            <xsl:variable name="hidden-property" select="codegen:getChildProperty($table,@name,$fk,1)" />
    var rp = this[ "<xsl:value-of select="$hidden-property"/>" ];
    if( rp instanceof Array )
    {
        rp.forEach( function( item )
        {
           childs.push( item );
        } );
    }</xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </xsl:for-each>
</xsl:for-each>
	
    return childs;
}</xsl:if>
//	endof _<xsl:value-of select="$class-name"/> class

</xsl:template>

  


  

  <!-- ==========================  CODEGEN.CLIENT.DATABASE -->
  <xsl:template name="codegen.client.database">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
//	================================================	<xsl:value-of select="$class-name"/>Db
function <xsl:value-of select="$class-name"/>Db()
{
    _<xsl:value-of select="$class-name"/>Db.call( this );
}
Utils.setInheritance( <xsl:value-of select="$class-name"/>Db, _<xsl:value-of select="$class-name"/>Db );

<xsl:value-of select="$class-name"/>Db.Instance = new <xsl:value-of select="$class-name"/>Db();
//	endof <xsl:value-of select="$class-name"/>Db class

</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.DATAMAPPERREGISTRY -->
  <xsl:template name="codegen.client.datamapperregistry">
//	================================================	DataMapperRegistry
function DataMapperRegistry()
{
	_DataMapperRegistry.call( this );
}
Utils.setInheritance( DataMapperRegistry, _DataMapperRegistry );

DataMapperRegistry.Instance = new DataMapperRegistry();
//	endof DataMapperRegistry class

</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.ACTIVERECORDS -->
  <xsl:template name="codegen.client.activerecords">
//	================================================	ActiveRecords
function ActiveRecords() { }
<xsl:for-each select="xs:complexType/xs:choice/xs:element[@wdm:DatabaseObjectType='table']">
<xsl:variable name="class-name" select="codegen:getClassName(@name)" />
ActiveRecords.<xsl:value-of select="$class-name"/> = DataMapperRegistry.Instance.get<xsl:value-of select="$class-name"/>();</xsl:for-each>
//	endof ActiveRecords class

</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.DATAMAPPER -->
  <xsl:template name="codegen.client.datamapper">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
//	================================================	<xsl:value-of select="$class-name"/>DataMapper
function <xsl:value-of select="$class-name"/>DataMapper()
{
    _<xsl:value-of select="$class-name"/>DataMapper.call( this );
}
Utils.setInheritance( <xsl:value-of select="$class-name"/>DataMapper, _<xsl:value-of select="$class-name"/>DataMapper );
//	endof _<xsl:value-of select="$class-name"/>DataMapper class

</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.DOMAIN -->
  <xsl:template name="codegen.client.domain">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
//	================================================	<xsl:value-of select="$class-name"/>
function <xsl:value-of select="$class-name"/>()
{
    _<xsl:value-of select="$class-name"/>.apply( this, arguments );
}
Utils.setInheritance( <xsl:value-of select="$class-name"/>, _<xsl:value-of select="$class-name"/> );

<xsl:value-of select="$class-name"/>.prototype.getRemoteClassName = function()
{
	return "<xsl:value-of select="codegen:getServerNamespace()" />.<xsl:value-of select="$class-name"/>";
}
//	endof _<xsl:value-of select="$class-name"/> class
  
</xsl:template>


  <!-- ==========================  CODEGEN.CLIENT.INIT -->
  <xsl:template name="codegen.client.init">
    <xsl:variable name="class-name" select="codegen:getClassName(@name)" />
    <xsl:variable name="var-name" select="codegen:getFunctionParameter(@name)" />
webORB.registerTypeFactory( "<xsl:value-of select="codegen:getServerNamespace()" />.<xsl:value-of select="$class-name"/>", function(object)
{
	  var <xsl:value-of select="$var-name"/> = new <xsl:value-of select="$class-name"/>();
	  Utils.copyValues( object, <xsl:value-of select="$var-name"/> );
	  <xsl:value-of select="$var-name"/>.ActiveRecordUID = object.ActiveRecordUID;
	  <xsl:value-of select="$var-name"/>.clearIsDirty();
	  return <xsl:value-of select="$var-name"/>;
} );
</xsl:template>


</xsl:stylesheet>