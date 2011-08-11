var divElement;
var consoleLog = null;

// base class for SocketsPubSubProxy and RemotingPubSubProxy, it contains only dispatchMessage method
function PubSubProxy( weborb )
{
  this.weborb = weborb;
  this.DSId = undefined;
  this.messageQueue = [];
}

PubSubProxy.prototype.dispatchMessage = function( message )
{
  // check if it is first response with DSId
  if ( this.DSId == undefined && message.headers.DSId != undefined ) 
  {      
    this.DSId = message.headers.DSId;
      
    // with DSId we may send messages from queue
    for( msg in this.messageQueue )
    {
      if ( consoleLog != undefined )
        consoleLog( "send message from queue" );  
      this.messageQueue[ msg ].headers.DSId = this.DSId;
      this.send( this.messageQueue[ msg ] );           
    }
    this.messageQueue.length = 0;
  } 
  // check if client is Producer
  else if ( this.weborb.producerOrConsumer.pullingInterval == undefined )
  {
    this.weborb.producerOrConsumer.handleIncomingMessage( message );   
  }  
  // check if it is meaningfull message for Consumer
  else if ( message.body != undefined )
  {         
    if ( webORB.isSocketFormatURL( this.weborb.connectionURL ) )
      this.weborb.producerOrConsumer.handleIncomingMessages( [message] );
    else
      this.weborb.producerOrConsumer.handleIncomingMessages( message.body );      
  }   
  else
  // response for subscription 
  {  
    // notify user that we are subscribed
    var producerOrConsumer = this.weborb.producerOrConsumer;
    if ( producerOrConsumer.subscribeAsync != undefined )        
    {
        producerOrConsumer.subscribeAsync.callback.call( producerOrConsumer.subscribeAsync.callbackOwner, message );
        producerOrConsumer.subscribeAsync = undefined;
    }
  }
}

function RemotingPubSubProxy( weborb )
{  
  PubSubProxy.call( this, weborb );       
}

RemotingPubSubProxy.prototype = new PubSubProxy();

RemotingPubSubProxy.prototype.send = function ( msg, ignoreDSId ) 
{       
  if ( consoleLog != undefined ) 
    consoleLog("trying to send message via remoting");   
         
  if ( this.DSId == undefined && (ignoreDSId == undefined || !ignoreDSId) )
  {
    if ( consoleLog != undefined )
      consoleLog("DSId isn't yet recieved - push message to queue");      
    this.messageQueue.push(msg);
    return;
  }    

  if ( consoleLog != undefined )
    consoleLog(msg);

  this.weborb.handleInvocation("sendWOLFPubSubMessage", "", null, [ msg, new Async(this.onResult, this.onFault, this)]);    
};

RemotingPubSubProxy.prototype.onFault = function( error )
{
  if ( consoleLog != undefined )
    consoleLog("onFault (remoting)")
  var async = this.weborb.producerOrConsumer.async;
  if ( async.faultCallback != undefined )
  {
    async.faultCallback.call( async.callbackOwner, error );
  }
  this.messageQueue.length = 0;   
};

RemotingPubSubProxy.prototype.onResult = function (message) 
{
  if ( consoleLog != undefined )
  {
    consoleLog( "received message (remoting)" );
    consoleLog(message);    
  }

  this.dispatchMessage(message);
};

function SocketPubSubProxy( weborb, reconnectUsingRemoting )
{
  PubSubProxy.call(this, weborb);
  this.reconnectUsingRemoting = reconnectUsingRemoting;  
  this.sock = undefined;  
  this.connect( weborb.connectionURL );
}

SocketPubSubProxy.prototype= new PubSubProxy();

SocketPubSubProxy.prototype.isWorking = function()
{
  return this.sock.readyState == this.sock.CONNECTING || this.sock.readyState == this.sock.OPEN;
};

SocketPubSubProxy.prototype.isConnected = function()
{
  return this.sock.readyState == this.sock.OPEN;
};

SocketPubSubProxy.prototype.send = function ( msg, ignoreDSId ) 
{      
  if ( consoleLog )  
    consoleLog("trying to send to socket");    

  if ( !this.isConnected() || (this.DSId == undefined && !ignoreDSId) )
  {
    if ( consoleLog != undefined )
      consoleLog("Not yet connected or DSId isn't yet recieved - push message to queue");      
    this.messageQueue.push(msg);
    return;
  }

  var funcName = "sendWOLFPubSubMessage";
  var targetName = "";
  var args = [msg];
  var requestXML = this.weborb.createRequestXML( funcName, targetName, args, false );        

  if( this.weborb.debugListener != null )
      this.weborb.debugListener.createdRequestDocument( requestXML );          

  // for IE
  if ( window.ActiveXObject )
    requestXML = requestXML.xml;
  else
  // for Firefox, Opera, etc
    requestXML = (new XMLSerializer()).serializeToString(requestXML);   
  
  if ( consoleLog != undefined )
    consoleLog( msg );   
  this.sock.send( requestXML );    
};

SocketPubSubProxy.prototype.sockOpen = function () 
{     
  if ( consoleLog != undefined )   
    consoleLog( "socket is connected" );

  if ( this.messageQueue.length > 0 )
  {
    if ( consoleLog != undefined )
      consoleLog("send message from queue to find out DSId");
    this.send( this.messageQueue[ 0 ], true );   
    this.messageQueue.splice(0, 1);   
  }
};

SocketPubSubProxy.prototype.onClosed = function( error )
{
  if ( consoleLog != undefined )
    consoleLog("onClosed (sockets)");
    
  if ( this.reconnectUsingRemoting ) 
  {      
    this.weborb.producerOrConsumer.switchToRemoting();   
    return;
  }

  var async = this.weborb.producerOrConsumer.async;
  if ( async.faultCallback != undefined )
  {
    async.faultCallback.call( async.callbackOwner, error );
  }
  this.messageQueue.length = 0;   
};

SocketPubSubProxy.prototype.sockError = function (error, p2) 
{    
  this.onClosed( error );
};

SocketPubSubProxy.prototype.sockClosed = function () 
{       
  this.onClosed();
};

SocketPubSubProxy.prototype.close = function () 
{       
  this.reconnectUsingRemoting = false;
  this.sock.close();
};

SocketPubSubProxy.prototype.sockMessage = function (event) 
{
  var data = event.data;

  // when in Chrome - remove first byte
//  if ( navigator.userAgent.toLowerCase().indexOf('chrome') > -1 )
//    data = data.substring(1, data.length-1);

  if ( consoleLog != undefined )
  {
    consoleLog( "received message (sockets)" );               
  }
  
  var message = this.weborb.parseResponse( data );

  if ( consoleLog != undefined )  
    consoleLog(message);  

  this.dispatchMessage(message);
};

SocketPubSubProxy.prototype.connect = function (url) 
{    
  try 
  {                    
    this.sock = new WebSocket( url );
    var self = this;
    this.sock.onopen = function() { return self.sockOpen.call( self ); };
    this.sock.onerror = function( error, p2 ) { return self.sockError.call( self, error, p2 ); };
    this.sock.onclose = function() { if ( self != undefined ) return self.sockClosed.call( self ); };
    this.sock.onmessage = function( event ) { return self.sockMessage.call( self, event ); };      
  } 
  catch (e) 
  {
      if ( consoleLog != undefined )
        consoleLog("error:" + e);
      throw e;
  }      
};

function V3Message()
{
  this.body = undefined;
  this.headers = new Object();
  this.messageId = guid();
}

function BodyHolder( data )
{  
  this.body = data;
  this.javascript_class_alias = "Weborb.V3Types.BodyHolder";
}

function CommandMessage( operation )
{ 
  V3Message.call(this);
  this.operation = operation;
  this.javascript_class_alias = "Weborb.V3Types.CommandMessage";
}

CommandMessage.prototype = new V3Message();

function AsyncMessage( data )
{  
  V3Message.call(this);
  this.javascript_class_alias = "Weborb.V3Types.AsyncMessage";
  this.body = data; 
}

AsyncMessage.prototype = new V3Message();

function Producer( destination, connectionURL, userid, password )
{
  if ( connectionURL )
    this.connectionURL = connectionURL;
  else 
  {
    this.reconnectUsingRemoting = true;
    this.connectionURL = webORB.getDefaultEndpoint( Producer.serverPort );
  }
  this.destination = destination;  
  this.userid = userid;
  this.password = password;
}

Producer.serverPort = 2037;

Producer.prototype =
{  
  connectionURL: undefined,
  destination: undefined,  
  async: undefined,  
  proxy: undefined,
  clientId: undefined,
  userid: undefined,
  password: undefined,
  reconnectUsingRemoting: undefined,
  reconnectionMessageQueue: [],

  handleIncomingMessage: function( message )
  {   
    if (this.async != undefined && this.async.callback != undefined )        
      this.async.callback.call( this.async.callbackOwner, message );  
  },

  send: function ( msg, async, subtopic, headers, clientId )
  {        
    // if socket connection fails, reconnectionMessageQueue will be passed to remoting proxy
    if ( webORB.isSocketFormatURL(this.connectionURL) && ( this.proxy == undefined || !this.proxy.isConnected() ) )
    {
      this.reconnectionMessageQueue.push( [msg, async, subtopic, headers, clientId] );
    }
        
    this.async = async;
    this.clientId = clientId;        
                         
    // create proxy only if it is undefined or isn't working (in case of sockets)
    if( this.proxy == undefined || ( webORB.isSocketFormatURL(this.connectionURL) && !this.proxy.isWorking()) ) 
    {              
      var webORBObj = new webORB( this.connectionURL, this.userid, this.password );         
      webORBObj.producerOrConsumer = this;
      
      this.proxy = webORB.isSocketFormatURL(this.connectionURL) ? new SocketPubSubProxy( webORBObj, this.reconnectUsingRemoting ) 
                                                                : new RemotingPubSubProxy( webORBObj );

      // request DSId
      var message = new CommandMessage();
      message.operation = "5";       
      this.proxy.send( message, true );   
    }          

    // send message to proxy (if proxy is newly created - message will be postponed to queue)    
    var message = new AsyncMessage(msg);  
    message.destination = this.destination;  

    if ( this.clientId )  
      message.clientId = this.clientId;  
    
    if ( headers ) 
      message.headers = headers;

    if ( subtopic )
      message.headers.DSSubtopic = subtopic;           

    this.proxy.send( message, true );
  },

  // this method is called from SocketPubSubProxy if it failed to connect to server
  switchToRemoting: function ()
  {
    if ( consoleLog != undefined )
      consoleLog("switch to remoting"); 

    // switch url to remoting endpoint    
    this.connectionURL = webORB.getDefaultRemotingEndpoint();       
        
    // proxy should be recreated
    this.proxy = undefined;    
    
    // resend requests using cached reconnectionMessageQueue
    for( var index in this.reconnectionMessageQueue  ) 
    {
      var m = this.reconnectionMessageQueue[ index ];
      this.send( m[0], m[1], m[2], m[3], m[4] );
    }
    this.reconnectionMessageQueue.length = 0;
  },

  close: function()
  {
    if ( this.proxy.close != undefined )        
      this.proxy.close();  
      
    this.proxy = undefined;  
  }
}

function Consumer(destination, async, connectionURL, clientId, selector, userid, password)
{
  if ( connectionURL )
    this.connectionURL = connectionURL;
  else 
  {
    this.reconnectUsingRemoting = true;
    this.connectionURL = webORB.getDefaultEndpoint( Consumer.serverPort );
  }
    
  this.async = async;
  this.destination = destination;  
  this.clientId = clientId;
  this.selector = selector;
  this.userid = userid;
  this.password = password;
}

Consumer.serverPort = 2037;

Consumer.prototype =
{  
  connectionURL: undefined,
  proxy: undefined,  
  destination: undefined,
  subtopic: undefined,  
  clientId: undefined,
  selector: undefined,
  userid: undefined,
  password: undefined,
  subscribeAsync: undefined,
  pullingInterval: 2000,
  isListening: false,  

  handleIncomingMessages: function( messages )
  {       
    for ( var i = 0; i < messages.length; i++)
    {                  
      if ( this.async.callback != undefined )        
        this.async.callback.call( this.async.callbackOwner, messages[i] )
    }      
  },

  // this is used only under remoting pub/sub
  pullMessage: function ()
  {      
    if ( !this.isListening )
      return;      
         
    if ( this.proxy.DSId )
    {
      var message = new CommandMessage();
      message.operation = "2";
      message.headers.DSId = this.proxy.DSId;   
      if ( this.clientId ) 
        message.clientId = this.clientId;
      this.proxy.send( message );
    }
    
    var self = this;
    setTimeout(function() { self.pullMessage.call(self); }, this.pullingInterval);
  },

  unsubscribe: function()
  {        
    if ( this.proxy != undefined && ( !webORB.isSocketFormatURL( this.connectionURL ) || 
                                      ( webORB.isSocketFormatURL( this.connectionURL ) && this.proxy.isWorking() ) 
                                    ) 
       )
    {
      var message = new CommandMessage();
      message.operation = "1";
      message.destination = this.destination;
      message.headers.DSId = this.proxy.DSId;

      if ( this.clientId ) 
        message.clientId = this.clientId;

      if ( this.subtopic )
        message.headers.DSSubtopic = this.subtopic;

      if ( this.selector )
        message.headers.DSSelector = this.selector;
      
      this.proxy.send( message );  
    }
  },

  subscribe: function ( subtopic, subscribeAsync )
  {
    this.unsubscribe();      

    this.subscribeAsync = subscribeAsync;    
    this.subtopic = subtopic;
    
    // recreate only if it isn't defined or isn't working
    if ( this.proxy == undefined || ( webORB.isSocketFormatURL( this.connectionURL ) && !this.proxy.isWorking() ) )
    {
      var webORBObj = new webORB( this.connectionURL, this.userid, this.password );         
      webORBObj.producerOrConsumer = this;
      
      this.proxy = webORB.isSocketFormatURL(this.connectionURL) ? new SocketPubSubProxy( webORBObj, this.reconnectUsingRemoting ) 
                                                                : new RemotingPubSubProxy( webORBObj );

      // request DSId
      var message = new CommandMessage();
      message.operation = "5";       
      this.proxy.send( message, true );                               
    }

    var message = new CommandMessage();
    message.operation = "0";
    message.destination = this.destination;
    message.headers.DSId = this.proxy.DSId;

    if ( this.clientId ) 
      message.clientId = this.clientId;

    if ( this.subtopic )
      message.headers.DSSubtopic = this.subtopic;

    if ( this.selector )
      message.headers.DSSelector = this.selector;
    
    var response = this.proxy.send( message );    
    
    this.isListening = true;   
     
    if ( !webORB.isSocketFormatURL(this.connectionURL) ) 
      this.pullMessage();
  }, 

  // this method is called from SocketPubSubProxy if it failed to connect to server
  switchToRemoting: function ()
  {
    if ( consoleLog != undefined )
      consoleLog("switch to remoting"); 

    // switch url to remoting endpoint    
    this.connectionURL = webORB.getDefaultRemotingEndpoint();       
        
    // proxy should be recreated
    this.proxy = undefined;    
    
    // resend request using cached arguments
    this.subscribe( this.subtopic, this.subscribeAsync );
  },

  close: function()
  {
    this.unsubscribe();   

    this.isListening = false;

    if ( this.proxy.close != undefined )        
      this.proxy.close();  
      
    this.proxy = undefined;  
  }
}

function webORB( connectionURL, userid, password )
{
    this.connectionURL = connectionURL;
    this.userid = userid;
    this.password = password;
    
    webORB.registerTypeFactory( "RecordSet", createRecordSet );
}

webORB.getDefaultEndpoint = function ( port )
{  
  if ( window.WebSocket ){
  var hostname = window.location.hostname;
  if(hostname == "" || hostname == null)
    hostname = "127.0.0.1";
    return "ws://" + hostname + ":" + port;
  }
  else 
    return webORB.getDefaultRemotingEndpoint();
};

webORB.getDefaultRemotingEndpoint = function()
{
	if( this.defaultRemotingURL != undefined )
		return this.defaultRemotingURL;
		
    var hostname = window.location.hostname;
    
	if(hostname == "" || hostname == null)
	{
	   var error = "Error! Unable to calculate a remoting URL. The HTML file is loaded from the file system, but needs to communicate with web server. The URL can be set using 'WebORB.setDefaultRemotingURL( urlValue )'";
	   alert( error );
	   throw error;
	}	
	else
	{
		var path = window.location.href;
		return path.substring(0, path.lastIndexOf('/') + 1) + "weborb.aspx";  
	}
}

webORB.setDefaultRemotingURL = function( defaultRemotingURL ) 
{
	this.defaultRemotingURL = defaultRemotingURL;
}

webORB.bind = function( targetName, connectionURL, userid, password )
{
    var webORBObj = new webORB( connectionURL, userid, password ); 
    var serviceDescriptor;
    
    try
    {
        serviceDescriptor = webORBObj.getClassMethods( targetName );    
    }
    catch( e )
    {
        alert( "error binding to object - " + e.description );
    }
    
    return webORB.createProxy( serviceDescriptor, targetName, webORBObj );
}

webORB.asyncBind = function( targetName, connectionURL, userid, password, async )
{
    var webORBObj = new webORB( connectionURL, userid, password ); 
    var serviceDescriptor;
    
    var originalCallback = async.callback;
    async.callback = new Function( "arguments.callee.originalCallback.call( this.callbackOwner, webORB.createProxy( arguments[ 0 ], arguments.callee.targetName, arguments.callee.webORBObj ) )" );    
    async.callback.webORBObj = webORBObj;
    async.callback.targetName = targetName;
    async.callback.originalCallback = originalCallback;
    webORBObj.getClassMethods( targetName, async );    
}

webORB.createProxy = function( serviceDescriptor, targetName, webORBObj )
{
    var proxy = new Object(); 

    for( var i = 0; i < serviceDescriptor.functions.length; i++)
    {
        var fName = serviceDescriptor.functions[ i ].name;
        
        proxy[ fName ] = new Function( "return arguments.callee.webORBObj.handleInvocation( arguments.callee._name, arguments.callee._targetname, this, arguments )" );
        proxy[ fName ]._name = fName;
        proxy[ fName ]._targetname = targetName;
        proxy[ fName ].webORBObj = webORBObj;
    }
    
    proxy.webORBObj = webORBObj;
    return proxy;
}

webORB.setCredentials = function( userid, password, proxy )
{
    proxy.webORBObj.setCredentials( userid, password );    
}

webORB.setCredentialsEncryptionFunction = function( func, proxy )
{
    proxy.webORBObj.setCredentialsEncryptionFunction( func );
}

webORB.setActivationMode = function( activationMode, proxy )
{
    proxy.webORBObj.setActivationMode( activationMode );
}

webORB.setDebugListener = function( debugListener, proxy )
{
    proxy.webORBObj.setDebugListener( debugListener );
}

webORB.factoryMethods = new Object();
webORB.registerTypeFactory = function( className, func )
{
    webORB.factoryMethods[ className ] = func;
}

webORB.isSocketFormatURL = function( connectionURL )
{
  return !(connectionURL.match("weborb.aspx$") == "weborb.aspx" );
}

webORB.prototype = 
{
    password: undefined,
    connectionURL: undefined,
    userid: undefined,
    requestid:1,
    encFunc: undefined,
    debugListener: undefined,
    pubSubAdapter: undefined,
    producerOrConsumer: undefined, 
    defaultRemotingURL:undefined,

    // *********************************************************************
    //                    METHOD TO RETRIEVE CLASS METHODS
    // *********************************************************************
    getClassMethods: function( targetName, async )
    {
        var request = "<WOLF version=\"1.0\"><Request id=\"0\"><Headers><InspectService><Boolean>true</Boolean></InspectService></Headers><Target>" + targetName + "</Target><Method>none</Method><Arguments /></Request></WOLF>";    
        var commObj = this.getRequestObject( async );
        
        if( async != null )
            async.setComm( commObj, this );
            
        var response = commObj.send( request );
/*
                text = "XML response from WebORB: <br />";
                text += "<textarea rows=\"50\" cols=\"75\">" + commObj.responseText + "</textarea><br /><br />";
                d = document.getElementById( "mydiv" );
                d.innerHTML = text;
*/
        if( async != null )
            return;
            
        if( commObj.responseXML.firstChild != null )
            return this.mainParse( commObj.responseXML );
        else 
            return this.parseResponse( commObj.responseText );
    },

    // *********************************************************************
    //                    RESPONSE PARSER
    // *********************************************************************
   parseResponse: function( responseText )
   {
       if( document.implementation && document.implementation.createDocument )
       {
           xmlDoc = document.implementation.createDocument( "","",null );
           Document.prototype._this = this;
           Document.prototype.loadXML = function( strXML ) 
           {
               var objDOMParser = new DOMParser();
               var objDoc = objDOMParser.parseFromString( strXML, "text/xml" );

             while( this.hasChildNodes() )
                   this.removeChild( this.lastChild );     

             if( typeof( this.importNode ) == "function")
             { 
                 for( var i = 0; i < objDoc.childNodes.length; i++ ) 
                     this.appendChild( objDoc.importNode( objDoc.childNodes[ i ], true ) );
             }
             else
             {
                 for( var i = 0; i < objDoc.childNodes.length; i++ ) 
                     this.appendChild( objDoc.childNodes[ i ].cloneNode( true ) );
             };

             //this._this.mainParse( this );
           }
       }
       else if( window.ActiveXObject )
       {
           xmlDoc = new ActiveXObject( "Microsoft.XMLDOM" );
           xmlDoc.async = false;
           xmlDoc.validateOnParse = false;
           /*
           xmlDoc.onreadystatechange = function () 
           {
           alert( xmlDoc.readyState );
               if( xmlDoc.readyState == 4 ) 
               {
                   this.mainParse( this );
               }
           };            
           */
       }
       else
       {
           alert('Your browser can\'t handle this script');
           return;
       }

       xmlDoc.loadXML( responseText );       
       return this.mainParse( xmlDoc );
    },
    
    // *********************************************************************
    //                    XMLHTTPREQUEST FACTORY
    // *********************************************************************
    getRequestObject: function( asyncObj )
    {       
        var req = null;             
        
        try 
        {
           req = new XMLHttpRequest();
        }
        catch( e )
        {
            var MSXML_XMLHTTP_PROGIDS = new Array(
                                                   'MSXML2.XMLHTTP.5.0',
                                                   'MSXML2.XMLHTTP.4.0',
                                                   'MSXML2.XMLHTTP.3.0',
                                                   'MSXML2.XMLHTTP',
                                                   'Microsoft.XMLHTTP'
                                                  );
           var success = false;
           for( var i=0; i < MSXML_XMLHTTP_PROGIDS.length && !success; i++)
           {
                try 
                {
                    req = new ActiveXObject( MSXML_XMLHTTP_PROGIDS[ i ] );
                    success = true;
                }
                catch( e )
                {
                }
           }
       }

        //if( this.userid != undefined && this.password != undefined )
        //    req.open( "POST", this.connectionURL, asyncObj != null, this.userid, this.password );
        //else
          try
          {                        
            req.open( "POST", this.connectionURL, asyncObj != null );
          }
          catch( e )
          {
            //if( e.number == -2147012891 )
            //  alert( "your browser security settings do now allow calls to domains other that the one where this script was loaded from" );
            
            throw e;
          }
         
            
        req.setRequestHeader( "Content-Type", "wolf/xml" );        

        req.onreadystatechange = function()
        {
               //alert( "in onreadystatechange " + req.readyState + "  " + req.responseText );
            
            //req.responseText = "";            
            
            if( asyncObj != null )
                asyncObj.setLastState( req.readyState );
        };

        return req;
    },
    
    mainParse: function( responseDoc )
    {
        var responseNode = responseDoc.firstChild.getElementsByTagName( "Response" )[ 0 ];
        
        if( responseNode != null )
            return this.parseData( responseNode.firstChild, new Array() );

        responseNode = responseDoc.firstChild.getElementsByTagName( "Fault" )[ 0 ];
        
        if( responseNode != null )
            throw this.parseData( responseNode.firstChild, new Array() );
    },
    
    parseData: function( dataElement, refMap )
    {
        switch( dataElement.nodeName )
        {
            case "Object":
                var refID = dataElement.getAttribute( "referenceID" );
                var obj = new Object();
                refMap[ refID ] = obj;                
                var childNodes = dataElement.childNodes;
                
                for( var i = 0; i < childNodes.length; i++ )
                {                
                    var fieldName = childNodes[ i ].getElementsByTagName( "Name" )[ 0 ].firstChild.nodeValue;
                    var fieldValueNode = childNodes[ i ].getElementsByTagName( "Value" )[ 0 ].firstChild;
                    var fieldValue = this.parseData( fieldValueNode, refMap );
                    obj[ fieldName ] = fieldValue;
                }
                
                var objName = dataElement.getAttribute( "objectName" );
                
                if( objName != undefined )
                {
                    var factoryMethod = this.getFactoryMethod( objName );
                    
                    if( factoryMethod != undefined )
                        return factoryMethod.call( null, obj, this );
                    else
                        return obj;                    
                }
                else
                {
                    return obj;
                }
                
                break;
            
            case "Boolean":
                return dataElement.firstChild.nodeValue == "true";
                break;
                
            case "Number":
                var strNum = dataElement.firstChild.nodeValue;
                
                var result;
                
                if( strNum.indexOf( '.' ) > -1 )
                    return parseFloat( strNum );
                else
                    return parseInt( strNum );
                    
                break;
            
            case "String":
                if(typeof( dataElement.textContent) != "undefined")
		   return dataElement.textContent;
		else if( dataElement.firstChild )
		   return dataElement.firstChild.nodeValue;
		else
		   return "";
		                    
                break;

            case "Undefined":
                return undefined;
                break;

            case "Date":
                return new Date( dataElement.firstChild.nodeValue );
                break;

            case "Array":
                var refID = dataElement.getAttribute( "referenceID" );
                var arrayObj = new Array( dataElement.childNodes.length );
                refMap[ refID ] = arrayObj;
                
                for( var i = 0; i < dataElement.childNodes.length; i++ )
                {
                    var arrayElement = this.parseData( dataElement.childNodes[ i ], refMap );
                    arrayObj[ i ] = arrayElement;
                }

                return arrayObj;                
                break;

            case "Reference":
                return refMap[ dataElement.firstChild.nodeValue ];
                break;

            case "XML":
                break;
            
            default:
                alert( "unknown data type - " + dataElement.nodeName );
                break;                
        }
    },
    
    handleInvocation: function( funcName, targetName, proxyObj, args )
    {        
        var asyncObj = this.getAsyncRequest( args );  
        var isAsync = (asyncObj != null);
        
        if( this.debugListener != null )
            this.debugListener.receivedInvocationRequest( funcName, targetName, isAsync );
                
        var commObj = this.getRequestObject( asyncObj );   
        
        var requestXML = this.createRequestXML( funcName, targetName, args, isAsync );

        if( this.debugListener != null )
            this.debugListener.createdRequestDocument( requestXML );

        if( isAsync )
            asyncObj.setComm( commObj, this );

        var response = null;                

        if( requestXML.xml )        
            response = commObj.send( requestXML.xml );        
        else        
            response = commObj.send( requestXML );            

        if( this.debugListener != null )
            this.debugListener.requestSent();
            

        if( isAsync )
            return;

        if( this.debugListener != null )
            this.debugListener.receivedResponse( commObj.responseText );

        return this.parseResponse( commObj.responseText );
    },
    
    createRequestXML: function( funcName, targetName, args, isAsync )
    {
        var requestXML = this.createDocument();
        var wolfElement = requestXML.createElement( "WOLF" );
        wolfElement.setAttribute( "version", "1.0" );
        requestXML.appendChild( wolfElement );

        var requestElement = requestXML.createElement( "Request" );
        requestElement.setAttribute( "id", this.requestid++ );
        wolfElement.appendChild( requestElement );
        
        if( this.userid != null && this.password != null )
        {
            var headerElement = requestXML.createElement( "Headers" );
            
            var credentialsObj = new Object();
            
            if( this.encFunc != undefined )
            {
                credentialsObj.userid = this.encFunc.call( null, this.userid );
                credentialsObj.password = this.encFunc.call( null, this.password );            
            }
            else
            {
                credentialsObj.userid = this.userid;
                credentialsObj.password = this.password;
            }                
            
            var credentialsElement = requestXML.createElement( "Credentials" );
            credentialsElement.appendChild( this.serializeObject( credentialsObj, requestXML ) );
            
            headerElement.appendChild( credentialsElement );            
            requestElement.appendChild( headerElement );
        }

        requestElement.appendChild( this.createElement( "Target", targetName, requestXML ) );
        requestElement.appendChild( this.createElement( "Method", funcName, requestXML ) );

        var argsElement = requestXML.createElement( "Arguments" );
        requestElement.appendChild( argsElement );

        var len = 0;
        
        if( args != undefined )
            len = isAsync ? args.length - 1 : args.length;

        for( var i = 0; i < len; i++ )
            argsElement.appendChild( this.serializeObject( args[ i ], requestXML ) );

        return requestXML;   
    },
    
    createDocument: function()
    {
        var requestXML;
        
        if( document.implementation && document.implementation.createDocument )
            requestXML = document.implementation.createDocument( "","",null );
        else if( window.ActiveXObject )
            requestXML = new ActiveXObject( "Microsoft.XMLDOM" );
        
    if (navigator.appName.indexOf("Opera") < 0)
    {    
          var pi;
          if ( !webORB.isSocketFormatURL(this.connectionURL) ) 
            pi = requestXML.createProcessingInstruction("xml", "version=\"1.0\" encoding=\"ISO-8859-1\"");
          else 
            pi = requestXML.createProcessingInstruction("xml", " version='1.0' encoding='UTF-8'");
  
          requestXML.appendChild(pi);
    }
        return requestXML;    
    },
    
    getAsyncRequest: function( args )
    {
        if( args == undefined || args.length == 0 || args[ args.length - 1 ] == null )
            return null;
            
        var constr = args[ args.length - 1 ].constructor;

        if( typeof( constr ) != "function" )
            return null;
                        
        var asyncCheck = constr.toString().match( /\s*function (.*)\(/ );

        if( asyncCheck != null && asyncCheck[ 1 ] == "Async" )
            return asyncObj = args[ args.length - 1 ];
        else
            return null;
    },
    
    serializeObject: function( obj, xmlNode )
    {
        switch( typeof( obj ) )
        {
            case "number":
                return this.createElement( 'Number', obj, xmlNode );
                break;
                
            case "string":
                return this.createElement( "String", obj, xmlNode );
                break;            
                
            case "boolean":
                return this.createElement( "Boolean", obj ? "true" : "false", xmlNode );
                break;
                
            case "object":
                if( obj == null )
                   return xmlNode.createElement( "Undefined" );
                else if( obj.constructor != null )
                {
                    switch( obj.constructor )
                    {
                        case Array:
                            var arrayElement = xmlNode.createElement( "Array" );
                            
                            for( var i = 0; i < obj.length; i++ )
                            {
                                var arrElementXML = this.serializeObject( obj[ i ], xmlNode );
                                arrayElement.appendChild( arrElementXML );
                            }
                            
                            return arrayElement;
                            break;
                            
                        case Date:
                            return this.createElement( "Date", obj.getTime(), xmlNode );                        
                            break;

                        case Object:
                            return this.createObjectElement( obj, undefined, xmlNode );
                            break;
                            
                        default:
              var className = typeof( obj.getRemoteClassName ) == "function"? obj.getRemoteClassName() : null;
              if ( !className )
              {
                              var strConst = obj.constructor.toString();
                              var aMatch = strConst.match( /\s*function (.*)\(/ );
                              if( aMatch != null )
                  className = aMatch[ 1 ];
              }
              
              if ( className )
                                return this.createObjectElement( obj, className, xmlNode );
                        
                            break;                        
                    }
                }
                break;
                
            case "function":
                break;
                
            case "undefined":
                return xmlNode.createElement( "Undefined" );
                break;
        }
    },

    createObjectElement: function( obj, objName, xmlNode )
    {
        var objElement = xmlNode.createElement( "Object" );

        if( objName != undefined )
            objElement.setAttribute( "objectName", objName );

        for( var name1 in obj )
        {
            if( typeof( obj[ name1 ] ) == "function" )
                continue;
                
            var fieldElement = xmlNode.createElement( "Field" );
            fieldElement.appendChild( this.createElement( "Name", name1, xmlNode ) );

            var valueElement = xmlNode.createElement( "Value" );
            valueElement.appendChild( this.serializeObject( obj[ name1 ], xmlNode ) );
            fieldElement.appendChild( valueElement );

            objElement.appendChild( fieldElement );
        }

        return objElement;    
    },
    
    createElement: function( elementName, elementValue, xmlNode )
    {
        var elementObj = xmlNode.createElement( elementName );
        var elementText = xmlNode.createTextNode( elementValue );
        elementObj.appendChild( elementText );        
        return elementObj;
    },
    
    getFactoryMethod: function( objectName )
    {
        return webORB.factoryMethods[ objectName ];
    },
    
    setCredentialsEncryptionFunction: function( func )
    {
        this.encFunc = func;
    },
    
    setCredentials: function( userid, password )
    {
        this.userid = userid;
        this.password = password;
    },
    
    setActivationMode: function( activationMode )
    {
        if( this.connectionURL.indexOf( "?" ) == -1 )
            this.connectionURL = this.connectionURL + "?activate=" + activationMode;
        else
        {
            if( this.connectionURL.indexOf( "activate=" ) == -1 )
            {
                if( this.connectionURL.charAt( this.connectionURL.length - 1 ) != '&' )
                    this.connectionURL += "&";
                
                this.connectionURL += "activate=" + activationMode;
            }
            else
            {
                var index = this.connectionURL.indexOf( "activate=" );
                var actLen = "activate=".length;
                
                var remainder = this.connectionURL.substr( index + actLen );
                var nextQueryParamIndex = remainder.indexOf( "&" );
                
                if( nextQueryParamIndex == -1 )
                    this.connectionURL = this.connectionURL.substr( 0, index ) + "activate=" + activationMode;
                else
                    this.connectionURL = this.connectionURL.substr( 0, index ) + "activate=" + activationMode + this.connectionURL.substr( nextQueryParamIndex );
            }
        }
    },
    
    setDebugListener: function( debugListener )
    {
        this.debugListener = debugListener;
    }
}

function base64( input ) 
{
   var keyStr = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=";
   var output = "";
   var chr1, chr2, chr3;
   var enc1, enc2, enc3, enc4;
   var i = 0;

   do 
   {
      chr1 = input.charCodeAt( i++ );
      chr2 = input.charCodeAt( i++ );
      chr3 = input.charCodeAt( i++ );

      enc1 = chr1 >> 2;
      enc2 = ((chr1 & 3) << 4) | (chr2 >> 4);
      enc3 = ((chr2 & 15) << 2) | (chr3 >> 6);
      enc4 = chr3 & 63;

      if( isNaN( chr2 ) ) 
         enc3 = enc4 = 64;
      else if ( isNaN( chr3 ) ) 
         enc4 = 64;

      output = output + keyStr.charAt( enc1 ) + keyStr.charAt( enc2 ) + keyStr.charAt( enc3 ) + keyStr.charAt( enc4 );
   } 
   while( i < input.length );

   return output;
}

function Async( successCallback, faultCallback, callbackOwner )
{
    this.callback = successCallback;
    this.faultCallback = faultCallback;
    this.callbackOwner = callbackOwner;
    this.commObj = undefined;
    this.webORBObj = undefined;
    this.stateNum = undefined;
    this.result = undefined;
    this.fault = undefined;    
    this.bufferingMode = false;
    this.bufferSize = undefined;
    this.lastResponseIndex = 0;
}

Async.prototype.setComm = function( commObj, webORBObj )
{
    this.commObj = commObj;
    this.webORBObj = webORBObj;
}

Async.prototype.setLastState = function( stateNum )
{
    this.stateNum = stateNum;
    
    if( this.bufferingMode )
    {
        if( this.stateNum == 3 )
        {
           var responseText = this.commObj.responseText;
           this.handleResponse( responseText.substr( this.lastResponseIndex ) );
           this.lastResponseIndex = responseText.length;
           
           if( this.lastResponseIndex >= this.bufferSize )
           {
              this.commObj.abort();
              this.lastResponseIndex = 0;
              webORB.subscribe( this.webORBObj.connectionURL, this, this.bufferSize );
              this.result = undefined;
              this.fault = undefined;
           }           
        }        
    }
    
    if( this.stateNum == 4 )
        this.handleResponse( this.commObj.responseText, this.commObj.responseXML );
}

Async.prototype.handleResponse = function( responseText, responseXML )
{
    if( responseText.length == 0 )
        return;
    
    var resultObj;    

    if( this.webORBObj.debugListener != null )
        this.webORBObj.debugListener.receivedResponse( responseText );

    try
    {
        if( responseXML )
            resultObj = this.webORBObj.mainParse( responseXML );
        else
            resultObj = this.webORBObj.parseResponse( responseText );        
    }
    catch( e )
    {
        this.fault = e;

        if( this.faultCallback == undefined )
            alert( "Exception: " + e.description );
        else
            this.faultCallback.call( this.callbackOwner, e );

        return;
    }

    this.result = resultObj;

    if( this.callback != undefined )
        this.callback.call( this.callbackOwner, resultObj );
}

Async.prototype.getStatus = function()
{
    return this.stateNum;
}

Async.prototype.getResult = function()
{
    return this.result;
}

Async.prototype.getFault = function()
{
    return this.fault;
}

Async.prototype.isSuccess = function()
{
    if( this.stateNum != 4 )
       throw "Cannot call isSuccess until getStatus() returns 4";
    
    return this.result != undefined;
}

Async.prototype.enableBufferingMode = function( bufferSize )
{
    //this.bufferingMode = true;
    this.bufferSize = bufferSize;
}

function RecordSet( serverInfo, webORBObj )
{
    this.serverInfo = serverInfo;
    this.webORBObj = webORBObj;
}

RecordSet.prototype = 
{
    getServerInfo: function()
    {
        return this.serverInfo;
    },

    getInitialPage: function()
    {
        return this.serverInfo.initialData;
    },

    getInitialPageSize: function()
    {
        if( this.serverInfo.initialData != undefined )
            return this.serverInfo.initialData.length;
        else
            return 0;
    },

    getPageSize : function()
    {
        return this.serverInfo.pagingSize;
    },

    getTotalRowCount : function()
    {
        return this.serverInfo.totalCount;
    },

    getColumnNames : function()
    {
        return this.serverInfo.columnNames;
    },

    getRecords : function( fromRow, rowsToGet, async )
    {
        var args = new Array( async == undefined ? 3 : 4 );
        args[ 0 ] = this.serverInfo.id;
        args[ 1 ] = Number( fromRow );
        args[ 2 ] = Number( rowsToGet );

        if( async != undefined )
            args[ 3 ] = async;

        return this.webORBObj.handleInvocation( "getRecords", this.serverInfo.serviceName, this, args );
    },

    cleanup : function( async )
    {
        var args = new Array( async == undefined ? 1 : 2 );
        args[ 0 ] = this.serverInfo.id;

        if( async != undefined )
            args[ 1 ] = async;

        return this.webORBObj.handleInvocation( "release", this.serverInfo.serviceName, this, args );
    }
}


function createRecordSet( recordSetInfo, webORBObj )
{
    return new RecordSet( recordSetInfo.serverInfo, webORBObj );
}

function Subscriber( webORBObj, serverPushObj, serverName, channelName, subscriberID )
{
    this.webORBObj = webORBObj;
    this.serverPushObj = serverPushObj;
    this.serverName = serverName;
    this.channelName = channelName;
    this.subscriberID = subscriberID;
    this.commObj = undefined;
    this.asyncObj = undefined;    
}

Subscriber.prototype.send = function( data, recepient )
{
    var requestDoc = this.webORBObj.createDocument();
    var messageElement = requestDoc.createElement( "Message" );
    requestDoc.appendChild( messageElement );
    
    if( recepient != undefined )
        messageElement.setAttribute( "deliverTo", recepient );
        
    if( this.serverName != undefined )
        messageElement.setAttribute( "serverName", this.serverName );
    
    if( this.channelName != undefined )
        messageElement.setAttribute( "channelName", this.channelName );

    messageElement.setAttribute( "subscriberID", this.subscriberID );        
    messageElement.appendChild( this.webORBObj.serializeObject( data, requestDoc ) );
    
    if( this.commObj == undefined )
    {
        this.asyncObj = new Async();
        this.commObj = this.webORBObj.getRequestObject( this.asyncObj );        
        this.commObj.setRequestHeader( "weborb-redirect", "/messagepost" );
        this.asyncObj.setComm( this.commObj, this.webORBObj );
    }
    
    if( requestDoc.xml )
        this.commObj.send( requestDoc.xml );
    else
        this.commObj.send( requestDoc );
}

Subscriber.prototype.getSubscriberID = function()
{
    return this.subscriberID;
}

function MessageServer( fp, hostName, port, callback )
{
    this.fp = fp; 
    this.hostName = hostName;
    this.port = port;
    this.callback = callback;
    this.channelCallbacks = new Object();
}

MessageServer.connect = function( hostName, port, callback, writeInMode )
{
    if( writeInMode == undefined )
        writeInMode = false;
        
    webORB.fp = new FlashProxy( uid, 'msgsrvr', 'jsfgw.swf', undefined, writeInMode ); 
    var fvars = {"lcId": uid};
    
    if( writeInMode )
        fvars = {"lcId": uid, "dofs": true };
    
    var tag = generateFT( 'msgsrvr.swf', 1, 1, "7,0,0,0", 'msgsrvr', fvars );

    if( !writeInMode )
    {
        divElement = document.createElement( "DIV" );
        divElement.id = "_jsfgw_";        
        divElement.width = 1;
        divElement.height = 1;
        divElement.innerHTML = tag;

        if( navigator.appName.indexOf ("Microsoft") != -1)
            document.appendChild( divElement );
        else
            document.body.appendChild( divElement );
    }
    else
    {
        document.write( "<div style=\"position:absolute;top:0px;left:0px;width:1px;height:1px;\">" + tag + "</div>");
    }

    var msgServer = new MessageServer( webORB.fp, hostName, port, callback );
    servers[ hostName + ":" + port ] = msgServer;
    
    if( !writeInMode )
        webORB.fp.call( "connect", hostName, port );
        
    return msgServer;
}

MessageServer.prototype.subscribe = function( channelName, subscribeAs, callback, createChannel, joinSilently )
{
    this.channelCallbacks[ channelName ] = callback;
    this.fp.call( "subscribe", channelName, subscribeAs, createChannel, joinSilently );
    return new Channel( this.fp, channelName );
}

MessageServer.prototype.handleMessage = function( messageObj, messageType, senderName, channelName, attribs )
{
    var messageCallback = this.callback;
    var channelCB = this.channelCallbacks[ channelName ];    
    
    if( channelCB != null )
        messageCallback = channelCB;    
    
    if( messageCallback != undefined )
        messageCallback.call( null, messageObj, messageType, senderName, channelName, attribs );
}

function Channel( fp, channelName )
{
    this.fp = fp;
    this.channelName = channelName;
}

Channel.prototype = 
{
    broadcast: function( messageObj, messageType, deliverToSelf )
    {
        this.fp.call( "broadcast", this.channelName, messageObj, messageType, deliverToSelf );
    },

    privateMessage: function( messageObj, deliverTo, messageType )
    {
        this.fp.call( "privateMessage", this.channelName, messageObj, deliverTo, messageType );
    },

    getSubscribers: function( subscribeToUpdates )
    {
        this.fp.call( "getSubscribers", this.channelName, subscribeToUpdates );
    },

    changeLogicalName: function( newName )
    {
        this.fp.call( "changeLogicalName", this.channelName, newName );
    },
    
    updateSubscriberName: function( newName )
    {
        this.fp.call( "updateSubscriberName",this.channelName, newName );
    },    
    
    invokeServer: function( messageObj, rootName, attribs )
    {
        this.fp.call( "invokeServer", this.channelName, messageObj, rootName, attribs );
    }
}

function __gotWOMessage__( hostName, port, messageObj, messageType, senderName, channelName, attribs )
{
    var server = servers[ hostName + ":" + port ];
    server.handleMessage( messageObj, messageType, senderName, channelName, attribs );
}

function __assemble__( id, numberOfParts, functionName )
{
    //document.getElementById( "debug" ).innerHTML += "__assemble___ " + id + "  " + eg + "  " + em + "<BR>";
    var pendingSplit = new Object();
    pendingSplit[ "functionName" ] = functionName;
    pendingSplit[ "totalParts" ] = numberOfParts;
    pendingSplit[ "parts" ] = new Array();
    splitParts[ id ] = pendingSplit;
}

function __addPart__( id, part )
{
    //document.getElementById( "debug" ).innerHTML += "__addPart__ " + id + "  " + fb + "<BR>";
    var pendingSplit = splitParts[ id ];
    pendingSplit[ "parts" ].push( part );
    
    if( eval( pendingSplit[ "totalParts" ] ) == pendingSplit[ "parts" ].length )
    {
        var finalString = "";
        
        for( var i = 0; i < pendingSplit[ "parts" ].length; i++ )
            finalString += pendingSplit[ "parts" ][ i ];
        
        FlashProxy.callJS( pendingSplit[ "functionName" ], "[" + finalString + "]" );
        delete splitParts[ id ];        
    }
}

function generateFT( swfName, width, height, version, id, fvars, fvarsStr )
{
    var flashTag = new String();
    var isie = (navigator.appName.indexOf ("Microsoft") != -1) ? 1 : 0;
    
    if( isie )
    {
        flashTag += '<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000" ';

        if( id != null )
            flashTag += 'id="' + id + '" ';

        flashTag += 'codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=' + version + '" ';
        flashTag += 'width="' + width + '" ';
        flashTag += 'height="' + height + '">';
        flashTag += '<param name="movie" value="' + swfName + '"/>';

        if( fvars != null )
        {
            var fv = fVarsToStr( fvars, fvarsStr );
            
            if( fv.length > 0 )
                flashTag += '<param name="flashvars" value="' + fv + '"/>';
        }
        flashTag += '</object>';
    }
    else
    {
        flashTag += '<embed src="' + swfName + '"';
        flashTag += ' width="' + width + '"';
        flashTag += ' height="' + height + '"';
        flashTag += ' type="application/x-shockwave-flash"';
        
        if( this.id != null )
            flashTag += ' name="' + id + '"';

        if( fvars != null )
        {
            var fv = fVarsToStr( fvars, fvarsStr );

            if( fv.length > 0 )
                flashTag += ' flashvars="' + fv + '"';
        }
        
        flashTag += ' pluginspage="http://www.macromedia.com/go/getflashplayer">';
        flashTag += '</embed>';
    }
    
    return flashTag;
}

function fVarsToStr( fvars, fvarsStr )
{
    var qs = new String();
    
    for( var n in fVars )
        if( fvars[ n ] != null )
            qs += ( escape( n ) + '=' + encodeURL( fvars[ n ] ) + '&');

    if( fvarsStr != null )
        return qs + fvarsStr;

    return qs.substring( 0, qs.length-1 );
}

function FlashProxy( lcId, flashId, proxySwfName, callbackScope, writeInMode )
{
    FlashProxy.fpmap[ lcId ] = this;
    this.uid = lcId;
    this.proxySwfName = proxySwfName;
    this.callbackScope = callbackScope;
    this.flashSerializer = new FlashSerializer( false );
    this.q = new Array();
    
    if( writeInMode )
    {
        if (navigator.appName.indexOf ('Internet Explorer') != -1 &&
            navigator.platform.indexOf('Win') != -1 &&
            navigator.userAgent.indexOf('Opera') == -1)
        {
            setUpVBCallback(fd);
        }    
    }
}

FlashProxy.prototype = 
{
    call: function()
    {
        this.q.push( arguments );

        if( this.q.length == 1 )
            this._execute( arguments );
    },

    _execute: function( args )
    {
        var fvarsStr = undefined;

        if( args.length > 1 )
        {
            var justArgs = new Array();

            for( var i = 1; i < args.length; ++i )
                justArgs.push( args[ i ] );

            fvarsStr = this.flashSerializer.serialize( justArgs );
        }

        var divName = '_flash_proxy_' + this.uid;

        if( !document.getElementById( divName ) )
        {
            var newTarget = document.createElement( "div" );
            newTarget.id = divName;
            newTarget.style.position = "absolute";
            newTarget.style.posWidth = "0px";
            newTarget.style.posHeight = "0px";
            newTarget.style.posTop = "0px";
            newTarget.style.posLeft = "0px";            
            document.body.appendChild( newTarget );
        }

        var target = document.getElementById( divName );
        var fvars = new Object();
        fvars[ 'lcId' ] = this.uid;
        fvars[ 'functionName' ] = args[ 0 ];
        target.innerHTML = generateFT( this.proxySwfName, 1, 1, '7,0,0,0', null, fvars, fvarsStr );
    }
}

FlashProxy.callJS = function( command, args )
{
    var argsArray = eval( args );
    var scope = FlashProxy.fpmap[ argsArray.shift() ].callbackScope;
    var functionToCall = scope ? scope[ command ] : eval( command );
    var thisObj = functionToCall;
    
    if( scope && ( command.indexOf('.') < 0 ) )
        thisObj = scope;
    
    functionToCall.apply( thisObj, argsArray );
}

FlashProxy.callComplete = function( uid )
{
    var fp = FlashProxy.fpmap[uid];
    
    if( fp != null )
    {
        fp.q.shift();

        if( fp.q.length > 0 )
            fp._execute( fp.q[ 0 ] );
    }
}

function FlashSerializer(useCdata)
{
    this.useCdata = useCdata;
}

FlashSerializer.prototype = 
{
    serialize: function( args )
    {
        var qs = new String();

        for( var i = 0; i < args.length; ++i )
        {
            switch( typeof( args[ i ] ) )
            {
                case 'undefined':
                    qs += 't' + ( i ) + '=undf';
                    break;
                case 'string':
                    qs += 't' + ( i ) + '=str&d' + ( i ) + '=' + args[ i ];
                    break;
                case 'number':
                    qs += 't' + ( i ) + '=num&d' + ( i ) + '=' + escape( args[ i ] );
                    break;
                case 'boolean':
                    qs += 't'+ ( i ) + '=bool&d' + ( i ) + '=' + escape( args[ i ] );
                    break;
                case 'object':
                    if( args[ i ] == null)
                    {
                        qs += 't'+(i)+'=null';
                    }
                    else if (args[i] instanceof Date)
                    {
                        qs += 't'+(i)+'=date&d'+(i)+'='+escape(args[i].getTime());
                    }
                    else // array or object
                    {
                        try
                        {
                            qs += 't'+(i)+'=xser&d'+(i)+'='+escape(this._serializeXML(args[i]));
                        }
                        catch( exception )
                        {
                            throw exception;
                        }
                    }
                    break;
            }

            if (i != (args.length - 1))
            {
                qs += '&';
            }
        }

        return qs;
    },

    _serializeXML: function(obj)
    {
        var doc = new Object();
        doc.xml = '<fp>'; 
        try
        {
            this._serializeNode(obj, doc, null);
        }
        catch (exception)
        {
            throw exception;
        }
        doc.xml += '</fp>'; 
        return doc.xml;
    },

    _serializeNode: function(obj, doc, name1)
    {
        switch(typeof(obj))
        {
            case 'undefined':
                doc.xml += '<undf'+this._addName(name1)+'/>';
                break;
            case 'string':
                doc.xml += '<str'+this._addName(name1)+'>'+this._escapeXml(obj)+'</str>';
                break;
            case 'number':
                doc.xml += '<num'+this._addName(name1)+'>'+obj+'</num>';
                break;
            case 'boolean':
                doc.xml += '<bool'+this._addName(name1)+' val="'+obj+'"/>';
                break;
            case 'object':
                if (obj == null)
                {
                    doc.xml += '<null'+this._addName(name1)+'/>';
                }
                else if (obj instanceof Date)
                {
                    doc.xml += '<date'+this._addName(name1)+'>'+obj.getTime()+'</date>';
                }
                else if (obj instanceof Array)
                {
                    doc.xml += '<array'+this._addName(name1)+'>';
                    for (var i = 0; i < obj.length; ++i)
                    {
                        this._serializeNode(obj[i], doc, null);
                    }
                    doc.xml += '</array>';
                }
                else
                {
                    doc.xml += '<obj'+this._addName(name1)+'>';
                    for (var n in obj)
                    {
                        if (typeof(obj[n]) == 'function')
                            continue;
                        this._serializeNode(obj[n], doc, n);
                    }
                    doc.xml += '</obj>';
                }
                break;
        }
    },

    _addName: function(name1)
    {
        if (name != null)
            return ' name="'+name1+'"';

        return '';
    },

    _escapeXml: function(str)
    {
        if (this.useCdata)
            return '<![CDATA['+str+']]>';
        else
            return str.replace(/&/g,'&amp;').replace(/</g,'&lt;');
    }
}

function encodeURL(str)
{
    if( typeof( str ) != 'string' )
        return str;

    var s0, i, s, u;
    s0 = "";                // encoded str

    for( i = 0; i < str.length; i++ )   // scan the source
    {

        s = str.charAt(i);
        u = str.charCodeAt(i);          // get unicode of the char

        if( s == " " )       // SP should be converted to "+"
            s0 += "+";

        else 
        {
            if( u == 0x2a || u == 0x2d || u == 0x2e || u == 0x5f || ((u >= 0x30) && (u <= 0x39 )) || (( u >= 0x41 ) && ( u <= 0x5a )) || (( u >= 0x61 ) && ( u <= 0x7a )))       // check for escape
            {
                s0 = s0 + s;            // don't escape
            }
            else                   // escape
            {
                if( (u >= 0x0) && (u <= 0x7f) )     // single byte format
                {
                    s = "0"+u.toString( 16 );
                    s0 += "%"+ s.substr( s.length - 2 );
                }
                else if( u > 0x1fffff )     // quaternary byte format (extended)
                {
                    s0 += "%" + ( 0xf0 + (( u & 0x1c0000) >> 18 )).toString( 16 );
                    s0 += "%" + ( 0x80 + (( u & 0x3f000) >> 12 )).toString( 16 );
                    s0 += "%" + ( 0x80 + (( u & 0xfc0) >> 6 )).toString( 16 );
                    s0 += "%" + ( 0x80 + ( u & 0x3f )).toString( 16 );
                }
                else if( u > 0x7ff )        // triple byte format
                {
                    s0 += "%" + ( 0xe0 + (( u & 0xf000 ) >> 12 )).toString( 16 );
                    s0 += "%" + ( 0x80 + (( u & 0xfc0 ) >> 6 )).toString( 16 );
                    s0 += "%" + ( 0x80 + ( u & 0x3f )).toString( 16 );
                }
                else                       // double byte format
                {
                    s0 += "%" + (0xc0 + ((u & 0x7c0) >> 6)).toString( 16 );
                    s0 += "%" + (0x80 + (u & 0x3f)).toString( 16 );
                }
            }
        }
    }    
    
    return s0;
}


function S4() 
{
   return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
}

function guid() 
{
   return (S4()+S4()+"-"+S4()+"-"+S4()+"-"+S4()+"-"+S4()+S4()+S4());
}

var splitParts = new Object();
var servers = new Object();
var uid = new Date().getTime();
FlashProxy.fpmap = new Object();
var tag;