var __$debug = true;

//	================================================	Array
/**
	Add some custom methods to Array class.
	forEach() and indexOf() are defined in JavaScript 1.6
	contains(), remove() and fromArguments() are helper functions
*/
if ( !Array.prototype.forEach )
{
	Array.prototype.forEach = function(func, contextObject)
	{
		for (var i = 0; i < this.length; ++i)
			func.call(contextObject, this[i], i, this);
	}
}

if ( !Array.prototype.indexOf )
{
	Array.prototype.indexOf = function(item)
	{
		for (var i = 0; i < this.length; ++i)
		{
			if (this[i] === item)
			return i;
		}
		return -1;
	}
}

Array.prototype.contains = function(item)
{
	return this.indexOf(item) >= 0;
}

Array.prototype.remove = function(item)
{
	var n = this.indexOf(item);
	if ( n >= 0 )
		this.splice(n, 1);
}

Array.fromArguments = function(args)
{
	var result = new Array( args.length );
	for (var i = 0; i < args.length; ++i)
		result[i] = args[i];
	return result;
}
//	endof Array methods


//	================================================	Collection
/**
	An Array-wrapper class. 
	IE doesn't allow to correctly inherit Array class, that's why Collection should be used.
*/
function Collection() { this._$arr = []; }
Collection.prototype.getLength = function() { return this._$arr.length; }
Collection.prototype.get = Collection.prototype.getItemAt = function(index) { return this._$arr[ index ]; }
Collection.prototype.set = Collection.prototype.setItemAt = function(index, value) { this._$arr[ index ] = value; }

Collection.prototype.pop = function() { return this._$arr.pop(); }
Collection.prototype.push = Collection.prototype.addItem = function() { return this._$arr.push.apply( this._$arr, arguments ); }
Collection.prototype.reverse = function() { return this._$arr.reverse(); }
Collection.prototype.shift = function() { return this._$arr.shift(); }
Collection.prototype.sort = function() { return this._$arr.sort.apply( this._$arr, arguments ); }
Collection.prototype.splice = function() { return this._$arr.splice.apply( this._$arr, arguments ); }
Collection.prototype.unshift = function() { return this._$arr.unshift.apply( this._$arr, arguments ); }
Collection.prototype.concat = function() { return this._$arr.concat.apply( this._$arr, arguments ); }
Collection.prototype.join = function() { return this._$arr.join(); }
Collection.prototype.slice = function() { return this._$arr.slice.apply( this._$arr, arguments ); }
Collection.prototype.toString = function() { return this._$arr.toString(); }

Collection.prototype.forEach = function() { return this._$arr.forEach.apply( this._$arr, arguments ); }
Collection.prototype.indexOf = function() { return this._$arr.indexOf.apply( this._$arr, arguments ); }
Collection.prototype.contains = function() { return this._$arr.contains.apply( this._$arr, arguments ); }
Collection.prototype.remove = Collection.prototype.removeItem = function() { return this._$arr.remove.apply( this._$arr, arguments ); }
Collection.prototype.removeItemAt = function( ndx ) { return this._$arr.splice( ndx, 1 ); }
Collection.prototype.clear = function() { this._$arr = [] }

Collection.prototype.getArray = function() { return this._$arr };
Collection.fromObject = function( obj )
{
	if( obj instanceof Collection )
		return obj;
		
	var result = new Collection();
	
	if( obj instanceof Array )
		result._$arr = obj;
	else if( obj != null )
		result.push( obj );
	
	return result;
}
//	endof Collection


//	================================================	Utils
function Utils()
{
}

Utils.setInheritance = function(subConstructor, superConstructor)
{
	subConstructor.prototype = new superConstructor();
	subConstructor.prototype.constructor = subConstructor;
}

Utils.copyMembers = function(srcObject, destObject)
{
	for (var m in srcObject)
	{
		if ( !(m in destObject) )
			destObject[m] = srcObject[m];
	}
}

Utils.copyValues = function(srcObject, destObject)
{
	for (var m in destObject)
	{
		if ( (m in srcObject) && !(destObject[m] instanceof Function) && !(srcObject[m] instanceof Function) )
			destObject[m] = srcObject[m];
	}
}

Utils.setPseudoInheritance = function(subConstructor, superConstructor)
{
	Utils.copyMembers(new superConstructor(), subConstructor.prototype);
}

Utils.isSimpleObject = function(obj)
{
	return typeof(obj) != 'object' || (obj instanceof Date) || (obj instanceof Array);
}

Utils.createClassProperty = function( _class, propName, initValue )
{
	Utils.createObjectProperty( _class.prototype, propName, initValue );
}

Utils.createObjectProperty = function( obj, propName, initValue, hideProp )
{
	var funcName = propName.charAt(0).toUpperCase() + propName.substr(1);

	if ( !hideProp )
	{
		var privateName = "_" + propName.charAt(0).toLowerCase() + propName.substr(1);
		obj[ privateName ] = initValue;
		obj[ "get" + funcName ] = function() { return this[ privateName ]; }
		obj[ "set" + funcName ] = function(value) { this[ privateName ] = value; }
	}
	else
	{
		var hiddenValue = initValue;
		obj[ "get" + funcName ] = function() { return hiddenValue; };
		obj[ "set" + funcName ] = function(value) { hiddenValue = value; };
	}
}

Utils.enablePropertyChangeTracking = function(_class, propName, getterName, setterName)
{
	if (!_class.prototype.dispatchEvent)
		throw "PropertyChangeTracking only available if the class is inherited from EventDispatcher.";
	
	var isGetterFunc = _class.prototype[ getterName ] instanceof Function;
	var originalSetter = _class.prototype[ setterName ];
	
	_class.prototype[ setterName ] = function()
	{
		var oldValue, newValue;
		
		try { oldValue = isGetterFunc? this[ getterName]() : this[ getterName ]; }
		catch (e) {}

		var result = originalSetter.apply( this, arguments );
		
		try { newValue = isGetterFunc? this[ getterName]() : this[ getterName ]; }
		catch (e) {}
		
		if (oldValue !== newValue)
			this.dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, propName, oldValue, newValue, this ) );
		
		return result;
	};
}

Utils.getClassName = function( obj )
{
	if ( obj == null )
		return "<null>";

	try { return /function\s+([^\s\(]+)/.exec( obj.constructor.toString() )[1]; }
	catch (e) { return typeof( obj ); }
}
//	endof Utils class






//	================================================	_EventMapEntry
function _EventMapEntry()
{
	this.contexts = [];
	this.handlers = [];
}

_EventMapEntry.prototype.getIndexOf = function(handler, context)
{
	for ( var i = 0; i < this.handlers.length; ++i )
	{
		if ( this.handlers[i] == handler && this.contexts[i] == context )
			return i;
	}
	return -1;
}

_EventMapEntry.prototype.remove = function( handler, contextObject )
{
	var ndx = this.getIndexOf( handler, contextObject );
	if ( ndx >= 0 )
	{
		this.contexts.splice( ndx, 1 );
		this.handlers.splice( ndx, 1 );
	}
}

_EventMapEntry.prototype.exclude = function( context )
{
	if ( context != null )
	{
		for ( var i = 0; i < this.handlers.length; ++i )
		{
			this.contexts.splice( i, 1 );
			this.handlers.splice( i, 1 );
			--i;
		}
	}
}
//	endof _EventMapEntry class


//	================================================	EventDispatcher
function EventDispatcher()
{
	this._eventMap = {};
}

EventDispatcher.prototype._hasHandler = function(eventName, handler, contextObject)
{
	var entry = this._eventMap[eventName];
	return entry != null && entry.getIndexOf( handler, contextObject ) >= 0;
}
	
EventDispatcher.prototype.hasEventListener = function(eventName)
{
	return this._eventMap[eventName] != null;
}

EventDispatcher.prototype.addEventListener = function( eventName, handler, contextObject )
{
	if ( !this._hasHandler( eventName, handler, contextObject ) )
	{
		var entry = this._eventMap[ eventName ];
		if ( entry == null )
			entry = this._eventMap[ eventName ] = new _EventMapEntry();
		entry.handlers.push( handler );
		entry.contexts.push( contextObject );
	}
}

EventDispatcher.prototype.removeEventListener = function(eventName, handler, contextObject)
{
	var entry = this._eventMap[ eventName ];
	if (entry != null)
	{
		if ( handler == null )
			entry.exclude( contextObject );
		else
			entry.remove( handler, contextObject );

		if ( entry.handlers.length == 0 )
			delete this._eventMap[ eventName ];
	}
}
	
EventDispatcher.prototype.dispatchEvent = function(event)
{
	var	entry = this._eventMap[event.type];
	if (entry != null)
	{
		event.target = this;
		for (var i = 0; i < entry.handlers.length; ++i)
		{
			var contextObject = entry.contexts[i];
			if (contextObject != null)
				entry.handlers[i].call(contextObject, event);
			else
				entry.handlers[i](event);
		}
	}
}
//	endof EventDispatcher class





//	DATA MANAGEMENT CLASSES

//	================================================	DataMapperProxy
function DataMapperProxy()
{
	EventDispatcher.call(this);
}

Utils.setInheritance(DataMapperProxy, EventDispatcher);

DataMapperProxy.prototype._createRemoteObject = function()
{
	return DataServiceClient.Instance.createRemoteObject( this.getRemoteClassName() );
}

DataMapperProxy.prototype.findBy = function( fields, valueArguments )
{
	var methodName = "findBy" + fields.toString();
	
	var args = Array.fromArguments( arguments );
	args.shift();
	
	var remoteObject = this._createRemoteObject();
	var responder = this._extractResponder( args );
	var options = this._extractOptions( args );
	var isAsync = responder instanceof Async;
	var activeCollection = this._extractActiveCollection( args );
	var dAsync = new DatabaseAsync();
	
	try
	{
		remoteObject.findDynamic( methodName, args, options, dAsync.wrapAsync( responder ) );
	}
	catch (error) 
	{
		__$showObject(error, "ERROR", true);
		throw "Unable to call method: " + methodName + ", " + error + ".";
	}  
	
	if( !isAsync )
	{
		return this._prepareCollection( dAsync, activeCollection, options );
	}
}

DataMapperProxy.prototype._prepareCollection = function( dAsync, activeCollection, options )
{
	if( activeCollection == null )
		activeCollection = new ActiveCollection( null, this, options );

	activeCollection.setIsLoading( true );
	dAsync.addResponder( new Responder(
		function( data ) { activeCollection.bindSource( data ); },
		function( e ) { alert( "Error loading data: " + e.description ); activeCollection.setIsLoading( false ); }
		)
	);
	
	return activeCollection;
}

DataMapperProxy.prototype._onFault = function(faultEvent)
{
}

DataMapperProxy.prototype._onInvoke = function(invokeEvent)
{
}

DataMapperProxy.prototype.getRemoteClassName = function()
{
	throw "Not implemented.";
}

DataMapperProxy.prototype._extractOptions = function(arr)
{
	var options = {};
	var isArray = arr instanceof Array;
	if ( arr != null && (isArray || arr.callee) && arr.length > 0 )
	{
		for (var i = 0; i < arr.length; ++i)
		{
			if ( !Utils.isSimpleObject( arr[i] ) && !( arr[i] instanceof Async ) && !( arr[i] instanceof ActiveCollection ) && !( arr[i] instanceof ActiveRecord ) )
			{
				options = arr[i];
				if (isArray)
					arr.splice(i, 1);
				break;
			}
		}
	}
	
	return options;
}

DataMapperProxy.prototype._extractResponder = function(arr)
{
	var responder = null;
	var isArray = arr instanceof Array;
	if ( arr != null && (isArray || arr.callee) && arr.length > 0 )
	{
		for (var i = 0; i < arr.length; ++i)
		{
			if ( arr[i] instanceof Async )
			{
				responder = arr[i];
				if (isArray)
					arr.splice(i, 1);
				break;
			}
		}
	}
	
	return responder;
}

DataMapperProxy.prototype._extractActiveCollection = function(arr)
{
	var activeCollection = null;
	var isArray = arr instanceof Array;
	if ( arr != null && (isArray || arr.callee) && arr.length > 0 )
	{
		for (var i = 0; i < arr.length; ++i)
		{
			if ( arr[i] instanceof ActiveCollection )
			{
				activeCollection = arr[i];
				if (isArray)
					arr.splice(i, 1);
				break;
			}
		}
	}
	
	return activeCollection;
}

DataMapperProxy.prototype.createActiveRecordInstance = function()
{
	throw "Not implemented.";
}

DataMapperProxy.prototype.fillPage = function( activeCollection, pageNumber, queryOptions, async )
{
	var remoteObject = this._createRemoteObject();
	var dAsync = new DatabaseAsync();
	
	dAsync.addResponder( 
		new Responder( 
			function(queryResult) { activeCollection.bindSource( queryResult ); }, 
			this._onFault,
			activeCollection,
			this 
		)
	);
	
	remoteObject.getQueryPage( activeCollection.getQueryId(), pageNumber, queryOptions, dAsync.wrapAsync( async ) );
}

DataMapperProxy.prototype.getDatabase = function()
{
	throw "Not implemented.";
}
//	endof DataMapperProxy class


//	================================================	DataMapper
function DataMapper()
{
	DataMapperProxy.call(this);
}

Utils.setInheritance(DataMapper, DataMapperProxy);

DataMapper.prototype.findAll = function()
{
	var remoteObject = this._createRemoteObject();
	var options = this._extractOptions( arguments );
	var responder = this._extractResponder( arguments );
	
	if( responder instanceof Async )
	{
		//	async call
		remoteObject.findAll( options, DatabaseAsync.wrapAsync( responder ) );
		return responder;
	}
	else
	{
		//	sync call
		var dAsync = new DatabaseAsync();
		responder = dAsync.wrapAsync( new Async(), null, true );
		remoteObject.findAll( options, DatabaseAsync.wrapAsync( responder, null, true ) );
		return this._prepareCollection( dAsync, null, options );
	}
}

DataMapper.prototype.findFirst = function()
{
	var remoteObject = this._createRemoteObject();
	var responder = this._extractResponder( arguments );
	var dAsync = new DatabaseAsync();
	
	remoteObject.findFirst( dAsync.wrapAsync( responder ) );
	if( responder instanceof Async )
		return responder;	//	async call
	else
		return this._prepareCollection( dAsync, null );	//	sync call
}

DataMapper.prototype.findLast = function()
{
	var remoteObject = this._createRemoteObject();
	var responder = this._extractResponder( arguments );
	var dAsync = new DatabaseAsync();
	
	remoteObject.findLast( dAsync.wrapAsync( responder ) );
	if( responder instanceof Async )
		return responder;	//	async call
	else
		return this._prepareCollection( dAsync, null );	//	sync call
}

DataMapper.prototype.loadChildRelation = function(activeRecord, propertyName, activeCollection)
{
	throw "Not implemented.";
}

DataMapper.prototype.findBySql = function( sqlQuery, args )
{
	var remoteObject = this._createRemoteObject();
	var options = this._extractOptions( arguments );
	var responder = this._extractResponder( arguments );

	if( responder instanceof Async )
	{
		//	async call
		remoteObject.findBySql( sqlQuery, options, DatabaseAsync.wrapAsync( responder ) );
		return responder;
	}
	else
	{
		//	sync call
		var dAsync = new DatabaseAsync();
		responder = dAsync.wrapAsync( new Async(), null, true );
		remoteObject.findBySql( sqlQuery, options, DatabaseAsync.wrapAsync( responder, null, true ) );
		return this._prepareCollection( dAsync, null, options );
	}
}
	
DataMapper.prototype._findBySql = function(sqlQuery, args)
{
	var options = this._extractOptions(arguments);
	var responder = this._extractResponder( arguments ) || new Async();
	var dAsync = new DatabaseAsync();
	var result = this._prepareCollection( dAsync, null, options );

	this.findBySqlAsync( sqlQuery, options, dAsync.wrapAsync( responder, null, true ) );
	return result;
}

DataMapper.prototype._findBySqlAsync = function(sqlQuery, args)
{
	var remoteObject = this._createRemoteObject();
	var responder = this._extractResponder( arguments );
	var options = this._extractOptions( arguments );
	
	remoteObject.findBySql( sqlQuery, options, DatabaseAsync.wrapAsync( responder ) );
	return responder;
}

DataMapper.prototype.save = function( activeRecord, cascade, responder)
{
	responder = this._extractResponder( arguments );
	cascade = cascade === true;

	if( activeRecord.getIsLocked() )
		throw "Record is locked and can't be saved.";

	if( activeRecord.getIsReadOnly() )
		throw "Record is read only and can't be saved.";


	var remoteObject = this._createRemoteObject();
	var extract = activeRecord.extractRelevant( cascade );
	remoteObject.save( extract, DatabaseAsync.wrapAsync( responder, activeRecord ) );

	return responder;
}

DataMapper.prototype.create = function( activeRecord, cascade, responder )
{
	responder = this._extractResponder( arguments );
	cascade = cascade === true;
	
	if( activeRecord.getIsLocked() )
		throw "Record is locked and can't be saved.";
	
	var remoteObject = this._createRemoteObject();
	remoteObject.create( activeRecord.extractRelevant( cascade ), DatabaseAsync.wrapAsync( responder, activeRecord ) );

	return responder;
}	 

DataMapper.prototype.update = function(activeRecord, cascade, responder)
{
	responder = this._extractResponder( arguments );
	cascade = cascade === true;
	
	if ( activeRecord.getIsLocked() )
		throw "Record is locked and can't be saved.";
	
	var remoteObject = this._createRemoteObject();
	remoteObject.update( activeRecord.extractRelevant( cascade ), DatabaseAsync.wrapAsync( responder, activeRecord ) );
	
	return responder;
}

DataMapper.prototype.removeAll = function( cascade, responder)
{
	responder = this._extractResponder( arguments );
	cascade = cascade !== false;

	var remoteObject = this._createRemoteObject();
	
	remoteObject.removeAll( DatabaseAsync.wrapAsync( responder ) );
	return responder;
}

DataMapper.prototype.remove = function( activeRecord, cascade, responder)
{
	responder = this._extractResponder( arguments );
	cascade = cascade !== false;
		
	if( activeRecord.getIsLocked() )
		throw "Record is locked and can't be deleted.";
	
	if( activeRecord.getIsReadOnly() )
		throw "Record is read only and can't be deleted.";
	
	var remoteObject = this._createRemoteObject();
	
	if (responder == null)
		responser = new Async();
	
	var dAsync = new DatabaseAsync();
	dAsync.addResponder( new Responder( 
		function()
		{
			activeRecord.setIsDeleted( true );
			activeRecord.setIsLocked( false );
			//DataServiceClient.Instance.onDeleted(activeRecord);
		}, 
		null)
	);

	remoteObject.remove( activeRecord.extractRelevant(false), cascade, dAsync.wrapAsync( responder, activeRecord ) );
	return responder;
}

DataMapper.prototype.getRowCount = function()
{
	this._createRemoteObject().getRowCount( DatabaseAsync.wrapAsync( this._extractResponder( arguments ) ) );
	return responder;
}

DataMapper.prototype.releaseQuery = function( activeCollection )
{
	this._createRemoteObject().releaseQuery( activeCollection.getQueryId(), DatabaseAsync.wrapAsync( this._extractResponder( arguments ) ) );
}

DataMapper.prototype._getRelationQueryOptions = function( relationName )
{
	return new Object();
}
//	endof DataMapper class


//	================================================	Responder
function Responder( resultCallback, faultCallback, contextObject, faultContextObject )
{
	this._result = resultCallback;
	this._fault = faultCallback;
	this._context = contextObject;
	this._faultContext = faultContextObject;
}

Responder.prototype.result = function()
{
	if ( this._result )
		this._result.apply( this._context, arguments );
}

Responder.prototype.fault = function()
{
	if ( this._fault )
		this._fault.apply( this._faultContext == null? this._context : this._faultContext, arguments );
}
//	endof Responder


//	================================================	DatabaseAsync
function DatabaseAsync(async, data)
{
	this._clientAsync = async;
	this._data = null;
	this._responders = [];
	
	this._setData( data );
}

DatabaseAsync.prototype._setData = function( data )
{
	if (data instanceof Array)
		this._data = data;
	else if (data instanceof ActiveRecord)
		this._data = [data];
	else if (data != null)
		throw "Just ActiveRecord or Array of ActiveRecord is allowed as argument for DatabaseAsync.";
	
	if (this._data != null)
		this._data.forEach( this._onBeforeSend, this );
}

DatabaseAsync.wrapAsync = function( async, data )
{
	var dAsync = new DatabaseAsync(async, data);
	return new Async(dAsync._onResult, dAsync._onFault, dAsync);
}

DatabaseAsync.prototype.wrapAsync = function( async, data, callbacksOnly )
{
	if ( (this._clientAsync != null && this._clientAsync != async) 
		|| (this._data != null && this._data != data) )
	{
		throw "Cannot wrap another async.";
	}
	
	this._clientAsync = async;
	this._setData( data );
	
	return callbacksOnly? 
		new Async( this._execCallbacks, null, this ) 
		: new Async( this._onResult, this._onFault, this );
}

DatabaseAsync.prototype.addResponder = function(responder)
{
	this._responders.push( responder );
}

DatabaseAsync.prototype._onBeforeSend = function(activeRecord)
{
	if( !IdentityMap.global.exists( activeRecord.ActiveRecordUID ) )
		IdentityMap.global.add( activeRecord, false );
	
	activeRecord.setIsLocked(true);
	
	activeRecord.extractChilds().forEach( this._onBeforeSend, this );
}

DatabaseAsync.prototype._onReceive = function(activeRecord)
{
	activeRecord.setIsLocked(false);
	var childs = activeRecord.extractChilds();
	if (childs != null )
		childs.forEach( this._onReceive, this );
}

DatabaseAsync.prototype._onResult = function(resultData)
{
	var finalResult = null;
	
	if ( this._data != null )
		this._data.forEach( this._onReceive, this );
					
	if (resultData instanceof ActiveRecord)
	{
		resultData.clearIsDirty();
		
		if (this._data != null)
			finalResult = this._processContextRecord( resultData );
		else
			finalResult = IdentityMap.global.processUnknownActiveRecord( resultData );
			
		IdentityMap.global.processChilds( resultData );
	}
	else if (resultData instanceof Array)
	{
		var processedArray = null;
		
		if (this._data != null)
		{
			processedArray = [];
			for (var i = 0; i < resultData.length; ++i)
			{
				var rec = resultData[i];
				processedArray.push( this._processContextRecord( rec ) );
				if (rec instanceof ActiveRecord)
					IdentityMap.global.processChilds( rec );
			}
		}
		else
		{
			processedArray = IdentityMap.global.processArray( resultData );
		}
		
		finalResult = processedArray;
	}
	else if( resultData instanceof QueryResult )
	{
		resultData.Result = IdentityMap.global.processArray( resultData.Result );
		finalResult = resultData;
	}
	else
		finalResult = resultData;
	
	//	exec callbacks
	this._execCallbacks( finalResult );
}

DatabaseAsync.prototype._execCallbacks = function( resultArg )
{
	this._responders.forEach( function(responder)
	{
		responder.result( resultArg );
	} );
	
	if ( this._clientAsync && this._clientAsync.callback )
	{
		this._clientAsync.callback.call( this._clientAsync.callbackOwner, resultArg );
	}
}

DatabaseAsync.prototype._processContextRecord = function( activeRecord )
{
	var contextActiveRecord = this._data.length == 1? this._data[0] : null;
			
	if( contextActiveRecord == null )
	{
		for (var i = 0; i < this._data.length; ++i)
		{
			contextActiveRecord = this._data[i];
			if( contextActiveRecord.ActiveRecordUID == activeRecord.ActiveRecordUID )
				break;
		}
	}
	
	if( contextActiveRecord != null )
	{
		contextActiveRecord.applyFields( activeRecord );
		
		if( IdentityMap.global.exists( contextActiveRecord.ActiveRecordUID ) )
			IdentityMap.global.remove( contextActiveRecord.ActiveRecordUID );
									
		contextActiveRecord.setIsLoaded( true );
		
		if( !IdentityMap.global.exists( contextActiveRecord.getURI() ) )
			IdentityMap.global.add( contextActiveRecord );

		contextActiveRecord.onReceived();
		
		return contextActiveRecord;
	}
	
	throw "Context record " + activeRecord.getURI() + " not found.";
}

DatabaseAsync.prototype._onFault = function(exception)
{
	__$alert("_onFault: " + exception);
	if (this._data != null)
		this._data.forEach( this._onReceive, this );
	
	//	exec callbacks
	this._responders.forEach( function(responder)
	{
		responder.fault( exception );
	} );
	
	if (this._clientAsync && this._clientAsync.faultCallback != null)
		this._clientAsync.faultCallback.call( this._clientAsync.callbackOwner, exception );
}
//	endof DatabaseAsync class


//	================================================	ColumnInfo
function ColumnInfo( name, type, isPK, isRequired )
{
	//	valid names for type are: "string", "int", "float", "date", "boolean"
	this.name = name;
	this.type = type;
	this.isPK = isPK;
	this.isRequired = isRequired;
}
ColumnInfo.defaultValues = { string: "", int: 0, float: 0, date: new Date( 1970, 0, 1 ), boolean: false };
//	endof ColumnsInfo class


//	================================================	ActiveRecord
function ActiveRecord()
{
	EventDispatcher.call(this);
	
	this.ActiveRecordUID = guid();
	this._externalProperies = {};
	this._prevIsDirty = false;
	this._isLoaded = false;
	this._lazyLoading = true;
	this._pendingChanges = [];
	this._relationDependentProperies = {};
	
	this._originalProperties = {};
	this._columnsInfo = [];
	
	Utils.createObjectProperty( this, "isLoading", false, true );
	Utils.createObjectProperty( this, "isLocked", false, true );
	Utils.createObjectProperty( this, "isReadOnly", false, true );
	Utils.createObjectProperty( this, "isDeleted", false, true );
}

Utils.setInheritance(ActiveRecord, EventDispatcher);

ActiveRecord.STATE_NEW = 0;
ActiveRecord.STATE_CREATED = 1;
ActiveRecord.STATE_SYNCHRONIZED = 2;
ActiveRecord.STATE_REMOVED = 3;

ActiveRecord.prototype.getColumnsInfo = function()
{
	return this._columnsInfo;
}

ActiveRecord.prototype._isLazyLoadingEnabled = function()
{
	return this._lazyLoading && this.getIsLoaded();
}

ActiveRecord.prototype.enableLazyLoading = function()
{
	this._lazyLoading = true;
}

ActiveRecord.prototype.disableLazyLoading = function()
{
	this._lazyLoading = false;
}
		
ActiveRecord.prototype.getPendingChanges = function()
{
	return this._pendingChanges;
}
		
ActiveRecord.prototype.getURI = function()
{
	throw "Not Implemented.";
}

ActiveRecord.prototype.isPrimaryKeyInitialized = function()
{
	throw "Not implemented.";
}


ActiveRecord.prototype.getIsLoaded = function()
{
	return this._isLoaded;
}

ActiveRecord.prototype.setIsLoaded = function(value)
{
	if( this.getIsLoaded() != value )
	{
		this._isLoaded = value;
		if( this.getIsLoaded() )
			this._onLoaded();
	}
}

ActiveRecord.prototype._onLoaded = function()
{
	this.dispatchEvent( new DynamicLoadEvent(this) );
}

ActiveRecord.prototype.getIsDirty = function()
{
	if( this.getIsLoading() || !this.getIsLoaded() )
		return true;
	
	var result = false;
	for ( var propName in this._originalProperties )
	{
		if( result = ( this[ propName ] != this._originalProperties[ propName ] ) )
			break;
	}
	
	if( result != this._prevIsDirty )
		this.dispatchEvent( new Event( Event.CHANGED ) );
	
	this._prevIsDirty = result;
	return result;
}

ActiveRecord.prototype._onChildRelationRequest = function(propertyName, activeCollection)
{
	if( !activeCollection )
	{
		var arrayReceived = false;
		
		if( this[ propertyName ] == null )
			this[ propertyName ] = [];
		else
			arrayReceived = true;
		
		var hiddenArray = this[ propertyName ];
		
		activeCollection = new ActiveCollection( hiddenArray );
		activeCollection.setIsLoaded( arrayReceived && this.getIsLoaded() );
	}

	if( this._isLazyLoadingEnabled() && activeCollection.getLength() == 0 && !( activeCollection.getIsLoaded() || activeCollection.getIsLoading() ) )
		this.getDataMapper().loadChildRelation( this, propertyName, activeCollection);
	    
	activeCollection.setOwner( this );
	
	return activeCollection;
}

ActiveRecord.prototype.onChildChanged = function(activeRecord)
{
	var oldValue = this.getIsDirty();
	
	if( activeRecord.getIsDirty() )
	{
		if( !this._pendingChanges.contains( activeRecord ) )
			this._pendingChanges.push( activeRecord );
	}
	else
	{
		if( this._pendingChanges.contains( activeRecord) )
			this._pendingChanges.remove( activeRecord );
	}
	
	if( oldValue != this.getIsDirty() )
		this.dispatchEvent( new PropertyChangeEvent( PropertyChangeEvent.PROPERTY_CHANGE, "isDirty", oldValue, this.getIsDirty(), this ) );
}

ActiveRecord.prototype.extractRelevant = function(cascade)
{
	return this.prepareToSend( new IdentityMap(), cascade );
}

ActiveRecord.prototype.prepareToSend = function(identityMap, cascade)
{
	return this;
}

function _PublicObjectActiveRecord() {};

ActiveRecord.prototype._getPublicObject = function()
{
	var result = new _PublicObjectActiveRecord();
	
	Utils.copyMembers( this, result );
	
	for( var propName in this )
	{
		if( propName.charAt( 0 ) == "_" )
			delete result[ propName ];
	}
	
	return result;
}

ActiveRecord.prototype.initRequiredFields = function()
{
	this._columnsInfo.forEach( function( colInfo )
	{
		if( colInfo.isRequired && this[ colInfo.name ] == null )
			this[ colInfo.name ] = ColumnInfo.defaultValues[ colInfo.type ];
	}, this );
}

ActiveRecord.prototype._registerExternalProperty = function( source, sourceProperty, destinationProperty )
{
	this._externalProperies[ destinationProperty ] =  function( event )
	{
		if( (event instanceof PropertyChangeEvent) && event.property == sourceProperty )
		{
			this.dispatchEvent( 
				new PropertyChangeEvent( 
					PropertyChangeEvent.PROPERTY_CHANGE,
					destinationProperty,
					event.oldValue,
					event.newValue,
					this
					)
				);
		}
	};

	source.addEventListener( PropertyChangeEvent.PROPERTY_CHANGE, this._externalProperies[ destinationProperty ] );
}

ActiveRecord.prototype.extractChilds = function()
{
	return new Array();
}

ActiveRecord.prototype._registerRelationDependentProperty = function( relationClassName, propertyName )
{
	if( this._relationDependentProperies == null)
		this.relationDependentProperies = {};

	var props = []
	for (var i = 1; i < arguments.length; ++i)
		props.push( arguments[i] );
	this._relationDependentProperies[ relationClassName ] = props;
}

ActiveRecord.prototype._onParentChanged = function( oldParentRecord, newParentRecord )
{
	if( this._relationDependentProperies != null && newParentRecord != null)
	{
		var propertyNames = this._relationDependentProperies[ Utils.getClassName( newParentRecord ) ];
		
		if (propertyNames != null)
		{
			propertyNames.forEach( function(eachProperty)
			{
				this.dispatchEvent(
					new PropertyChangeEvent( 
						PropertyChangeEvent.PROPERTY_CHANGE,
						eachProperty,
						null,
						this[ eachProperty ],
						this
						)
					);
			} );
		}
	}
}
		
		
ActiveRecord.prototype.getDataMapper = function()
{
	throw "Not Implemented.";
}

ActiveRecord.prototype.create = function( cascade, async )
{
	return this.getDataMapper().create( this, cascade, async );
}

ActiveRecord.prototype.onReceived = function()
{
	this.setIsLoading( false );
	this.clearIsDirty();
	this.setIsLoaded( true );
}

ActiveRecord.prototype.clearIsDirty = function()
{
	for ( var propName in this._originalProperties )
		this._originalProperties[ propName ] = this[ propName ];
}

ActiveRecord.prototype.remove = function( cascade, responder)
{
	return this.getDataMapper().remove( this, cascade, responder);
}

ActiveRecord.prototype.applyFields = function( object )
{
}

ActiveRecord.prototype.revertChanges = function()
{
	for ( propName in this._originalProperties )
		this[ propName ] = this._originalProperties[ propName ];
}

ActiveRecord.prototype.save = function (cascade, responder)
{
	return this.getDataMapper().save( this, cascade, responder );
}

ActiveRecord.prototype.equals = function( activeRecord )
{
	for( var i = 0; i < this._columnsInfo.length; ++i )
	{
		var n = this._columnsInfo[ i ].name;
		if( this[ n ].valueOf() !== activeRecord[ n ].valueOf() )
			return false;
	}	
	return true;
}
//	endof class ActiveRecord


//	================================================	QueryResult
function QueryResult()
{
	this.QueryId = null;
	this.IsPaged = null;
	this.IsMonitored = null;
	this.StartIndex = null;
	this.TotalRows = null;
	this.Result = [];
	this.IsInitional = null;
	this.PageNumber = null;
	this.PageSize = null;
}
//	endof class QueryResult

//	================================================	ActiveCollection
function ActiveCollection(source, dataMapper, options)
{
	Collection.call(this);
	EventDispatcher.call(this);
	
	this._isLoaded = false;
	this._isLoading = false;
	this._queryResult = null;
	this._paged = false;
	this._pageSize = 0;
	this._loadedPages = [];
	this._loadingPages = [];
	this._dataMapper = dataMapper;
	this._lastPageRequest = new Date();
	this._limit = 0;
	this._lastOnTop = false;
	this._options = options;
	this._monitored = false;
	this._stubLoadingRecord = null;
	Utils.createObjectProperty( this, "owner", null, true );
	
	if( source && (source instanceof Array && source.length > 0 || source instanceof Collection && source.getLength() > 0 ) )
	{
		var sCol = Collection.fromObject( source );
		for (var i = 0; i < source.getLength(); ++i)
		{
			if ( !(source.get(i) instanceof ActiveRecord ) )
				throw "Only active records can be added in collection.";
			this.push( source.get(i) );
		}
		this._isLoaded = true;
	}
	
	if( options != null )
	{
		if( dataMapper != null)
		{  		
			if( options.Monitored )
				this._monitored = true;
		}
		
		if( options.Limit )
			this._limit = parseInt( options.Limit );
		
		if( options.LastOnTop )
			this._lastOnTop = true;
	}

	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.DELETE, this._onItemDeleted, this );
}

Utils.setInheritance( ActiveCollection, Collection );
Utils.setPseudoInheritance( ActiveCollection, EventDispatcher );

ActiveCollection.PAGE_EMPTY = 0;
ActiveCollection.PAGE_LOADING = 1;
ActiveCollection.PAGE_LOADED = 2;
ActiveCollection.LIMIT_PAGE_LOAD = 1;

ActiveCollection.prototype.clear = function()
{
	Collection.prototype.clear.call( this );
	this._loadedPages = [];
	this._loadingPages = [];
}

ActiveCollection.prototype.isAllPagesLoaded = function()
{
	return this._loadedPages.length == Math.floor(this.length / this._pageSize) + 1;
}

ActiveCollection.prototype.bindSource = function(source)
{
	var events = [];
	
	if( source instanceof QueryResult)
	{
		this._queryResult = source;
		
		if( this._queryResult.IsInitional )
		{
			if( this._queryResult.IsMonitored )
			{
				this._monitored = true;
				DataServiceClient.Instance.addEventListener( ActiveRecordEvent.CREATE, this._onItemCreated, this );
			}
			
			this._paged = this._queryResult.IsPaged;
			this._pageSize = this._queryResult.PageSize;
			
			if( this._paged )
				this._$arr.length = this._queryResult.TotalRows;// + this._$arr.length;
		}
		
		if( this._queryResult.IsPaged )
		{
			//if( this._$arr.length == 0 )
			//	this._$arr.length = this._queryResult.TotalRows;
				
			if( this._loadedPages.contains( this._queryResult.PageNumber) )
				throw "Page #" + this._queryResult.PageNumber + " already loaded.";
			
			this._loadedPages.push( this._queryResult.PageNumber );
			
			if( this._loadingPages.contains( this._queryResult.PageNumber) )
				this._loadingPages.remove( this._queryResult.PageNumber );
			
			
			events.push( new PagingEvent( this._queryResult.PageNumber ) );
		}
		
		var insertIndex = this._queryResult.StartIndex;
		
		for (var i = 0; i < this._queryResult.Result.length; ++i)
		{
			var item = this._queryResult.Result[ i ];
			
			if (this._paged)
				this.set( insertIndex++, item );
			else
				this.splice( insertIndex++, 0, item);
		}
		
		if( this._queryResult.IsInitional )
		{
			//this.refresh();
			events.push( new DynamicLoadEvent( this ) );
		}
		else
			events.push( new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, CollectionEventKind.ADD ) );
	}
	else if( source instanceof Array )
	{
		for (var i = 0; i < source.length; ++i)
			this.push( source[i] );
	
		events.push( new DynamicLoadEvent(this) );
	}
	else if( source instanceof ActiveRecord )
	{
		this.push( source );
		events.push( new DynamicLoadEvent( this ) );
	}
	
	this.setIsLoaded( this._loadingPages.length == 0 );
	this.setIsLoading( !this.getIsLoaded() );
	
	for (var i = 0; i < events.length; ++i)
		this.dispatchEvent( events[i] );
}

ActiveCollection.prototype.addCollection = function( activeCollection )
{
	this.addCollectionAt( activeCollection, this.length );
}

ActiveCollection.prototype.addCollectionAt = function( activeCollection, index )
{
	if( activeCollection.getIsLoading() )
	{
		activeCollection.addEventListener(DynamicLoadEvent.LOADED,
			function(event)
			{
				this.addCollectionAt( event.data, index );
			},
			this
		);
	}
	else
	{
		activeCollection.forEach( function(activeRecord)
		{
			this.addItemAt(activeRecord, index);
		} );
		
		activeCollection.addEventListener( ActiveRecordEvent.CREATE, _onChainCollectionChanges, this );
		activeCollection.addEventListener( ActiveRecordEvent.DELETE, _onChainCollectionChanges, this );
	}
}

ActiveCollection.prototype.addItem = ActiveCollection.prototype.push = function( activeRecordOrColl )
{
	if( this._lastOnTop )
		this.addItemAt( activeRecordOrColl, 0 );
	else
		this.addItemAt( activeRecordOrColl, this.length );
}

ActiveCollection.prototype.addItemAt = function( activeRecord, index )
{
	if( this._limit > 0 && this._limit == this.getLength() )
		throw "Collection has limit on " + this._limit + " records.";
	
	if( activeRecord instanceof ActiveCollection)
	{
		this.addCollectionAt( activeRecord, index );
		return;
	}
	
	if( !activeRecord.ActiveRecordUID )
		throw "Only active records can be added in collection.";
	
	if( !this.contains( activeRecord ) )
	{
		if( activeRecord instanceof ActiveRecord )
		{
			activeRecord.addEventListener( ActiveRecordEvent.DELETE, this._onItemDeleted, this );
			
			if( this.getOwner() )
			{
				activeRecord.dispatchEvent( new RelationEvent(RelationEvent.RELATION_ADD, this, activeRecord ) );
			}
		}
		this.splice( index, 0, activeRecord );
	}
	else
		return;
	
	this.dispatchEvent( new ActiveRecordEvent( ActiveRecordEvent.CREATE, activeRecord ) );
	
	this._isLoaded = true;
}

ActiveCollection.prototype.getItemAt = ActiveCollection.prototype.get = function( index )	//,	prefetch )
{
	if( this._paged )
	{
		var pageNumber = this._getPageNumber( index );
		
		if(! this._loadedPages.contains( pageNumber ) )
		{
			if( this._loadingPages.length < ActiveCollection.LIMIT_PAGE_LOAD && !this._loadingPages.contains( pageNumber ) )
			{
				this._loadingPages.push( pageNumber );
				this._dataMapper.fillPage( this, pageNumber, this._options ); 
			}
			
			if( this._stubLoadingRecord == null )
			{
				this._stubLoadingRecord = this._dataMapper.createActiveRecordInstance();
				this._stubLoadingRecord.setIsLoading( true );
			}
		
			return this._stubLoadingRecord; 
		}
	}
	
	return Collection.prototype.get.call( this, index );
}

ActiveCollection.prototype.containsUri = function( uri )
{
	this.forEach( function( activeRecord )
	{
		if ( activeRecord.ActiveRecordUID == uri )
			return true;
	} );

	return false;
}

ActiveCollection.prototype._getPageNumber = function( index )
{
	var pageNumber = parseInt( ++index / this._pageSize );
	
	if( (index % this._pageSize) || pageNumber == 0 )
		++pageNumber;
	
	return pageNumber;
}

ActiveCollection.prototype.getIsLoaded = function()
{
	return this._isLoaded || this.length > 0;
}
 
ActiveCollection.prototype.setIsLoaded = function( value )
{
	this._isLoaded = value;
}
 
ActiveCollection.prototype.getIsLoading = function()
{
	return this._isLoading;
}
 
ActiveCollection.prototype.setIsLoading = function( value )
{
	this._isLoading = value;
}

ActiveCollection.prototype._onChainCollectionChanges = function( event )
{
	if( event.type == ActiveRecordEvent.CREATE )
		this.addItem( event.record );
	else if( event.type == ActiveRecordEvent.DELETE )
	{
		var i = this.indexOf( event.record );
		if( i > 0 )
			this.removeItemAt( i );
	}
}

ActiveCollection.prototype._onItemCreated = function( event )
{	
	try
	{
		if( event.matchQueries != null && this._queryResult != null 
			&& event.matchQueries.indexOf( this._queryResult.QueryId ) != -1 
			&& !this.contains( event.record ) )
		{
			if( this._limit > 0 && this.length == this._limit )
			{
				if( this._lastOnTop )
					this.removeItemAt( this.length - 1 );
				else
					this.removeItemAt( 0 );
			}
			this.addItem( event.record );
		}
	}
	catch( e )
	{
		
	}
}
		
ActiveCollection.prototype._onItemDeleted = function( event )
{
	var itemIndex;
	
	try
	{
		itemIndex = this.indexOf( event.record );
	}
	catch( exception )
	{
		return;
	}
	
	if( itemIndex >= 0 )
		this.removeItemAt( itemIndex );
}

ActiveCollection.prototype.getQueryId = function()
{
	return this._queryResult != null? this._queryResult.QueryId : guid();
}

ActiveCollection.prototype.release = function()
{
	if( this._monitored && this._dataMapper != null )
		this._dataMapper.releaseQuery( this );
}

ActiveCollection.prototype.removeItem = ActiveCollection.prototype.remove = function( activeRecord )
{
	var index = this.indexOf( activeRecord );
	
	if( index >= 0 )
		return this.removeItemAt( index );
	
	return null;
}

ActiveCollection.prototype.removeItemAt = function( index)
{
	var activeRecord = this.get( index );
	this.splice( index, 1 );
	
	if( activeRecord instanceof ActiveRecord )
	{
		activeRecord.removeEventListener( ActiveRecordEvent.DELETE, this._onItemDeleted, this);
		
		if( this.getOwner() )
		{
			this.getOwner().dispatchEvent( new RelationEvent( RelationEvent.RELATION_DELETE, this, activeRecord ) );
		}
	}
	
	if( activeRecord instanceof ActiveRecord )
		this.dispatchEvent( new ActiveRecordEvent( ActiveRecordEvent.DELETE, activeRecord ) );
	
	return activeRecord;
}

//	endof class ActiveCollection


//	================================================	IdentityMap
function IdentityMap()
{
	this._count = 0;
	this._items = {};
}

IdentityMap.global = new IdentityMap();

IdentityMap.prototype.add = function(activeRecord, useUri)
{
	useUri = (useUri == null) || useUri;
	var key = ( activeRecord.isPrimaryKeyInitialized() && useUri ) ? activeRecord.getURI() : activeRecord.ActiveRecordUID;
	if( key == null )
		throw "Key can't be null.";
	
	if( this.exists( key ) )
		throw "Active record with uri " + activeRecord.getURI() + " already exists.";
	
	this._items[ key ] = activeRecord;
	++this._count;
}

IdentityMap.add = function(activeRecord, useUri)
{
	useUri = (useUri == null) || useUri;
	IdentityMap.global.add(activeRecord, useUri);
}

IdentityMap.prototype.register = function(activeRecord)
{
	var registeredActiveRecord = null;
	
	if( activeRecord.isPrimaryKeyInitialized() && this._items[ activeRecord.getURI() ] )
		registeredActiveRecord = this.extract( activeRecord.getURI() );
	else if( this._items[ activeRecord.ActiveRecordUID ])
		registeredActiveRecord = this.extract( activeRecord.ActiveRecordUID );

	if( registeredActiveRecord != null )
	{
		if( activeRecord != registeredActiveRecord )
			activeRecord.clearIsDirty();
		
		return registeredActiveRecord;
	}
	else
	{
		this.add( activeRecord );
	}
		
	return activeRecord;
}

IdentityMap.register = function(activeRecord)
{
	return IdentityMap.global.register(activeRecord);
}

IdentityMap.prototype.remove = function(uri)
{
	--this._count;
	delete this._items[uri];
}

IdentityMap.prototype.getCount = function()
{
	return this._count;
}

IdentityMap.exists = function(uri)
{
	return IdentityMap.global.exists(uri);
}

IdentityMap.prototype.exists = function(uri)
{
	return this._items[uri] != null;
}	

IdentityMap.extract = function(uri)
{
	return IdentityMap.global.extract(uri);
}

IdentityMap.prototype.extract = function(uri)
{
	return this._items[uri];
}

IdentityMap.prototype.processArray = function(array)
{
	var processedArray = [];
	
	array.forEach( function(item)
	{
		if( item instanceof ActiveRecord)
		{
			this.processChilds(item);
			processedArray.push( this.processUnknownActiveRecord(item) );
		}
		else
			processedArray.push( item );
	}, this );
	
	return processedArray;
}

IdentityMap.prototype.processUnknownActiveRecord = function( activeRecord )
{
	var registeredActiveRecord;

	activeRecord.clearIsDirty();
	
	if( this.exists( activeRecord.ActiveRecordUID ) )
	{
		registeredActiveRecord = this.extract( activeRecord.ActiveRecordUID );
		this.remove( activeRecord.ActiveRecordUID );
	}
	
	if( this.exists( activeRecord.getURI() ) )
	{
		registeredActiveRecord = this.extract( activeRecord.getURI() );
	}

	if( registeredActiveRecord != null )
		registeredActiveRecord.applyFields( activeRecord );
	else
		registeredActiveRecord = activeRecord;

	if( !this.exists( registeredActiveRecord.getURI() ) )
		this.add( registeredActiveRecord, true);
			
	registeredActiveRecord.onReceived();
					
	return registeredActiveRecord;
}

IdentityMap.prototype.processChilds = function(activeRecord)
{
	activeRecord.extractChilds().forEach( function(item)
	{
		this.processUnknownActiveRecord(item);
		this.processChilds(item);
	}, this );
}
//	endof class IdentityMap


//	================================================	PagedDataModel
function PagedDataModel()
{
	Collection.call( this );
	
	this._queryId = "";
	this._pageSize = 0;
	this._loadedPages = [];
	this._loadingPages = [];
	this._listener = null;
	this._lastEmptyRow = 0;
	this._timer = null;
	
	this.defaultRecord = null;
	this.defaultRecordLoadingField = null;
	this.inverseSortFlag = false;
	this.sortField = null;
	this.descending = false;
	this.maxPagesInMemory = 0;
}

Utils.setInheritance( PagedDataModel, Collection );
Utils.setPseudoInheritance( PagedDataModel, EventDispatcher );

PagedDataModel.PAGE_LOADING_LIMIT = 5;

PagedDataModel.prototype.getQueryId = function()
{
	return this._queryId;
}

PagedDataModel.prototype.bindPagedResult = function( pagedQueryResult, dataSource )
{
	if(	pagedQueryResult.PageNumber == 1 )
	{				
		if( dataSource == null )
			throw "DataSource is required for the first page.";
		
		this._queryId = pagedQueryResult.QueryId;
		this._pageSize = pagedQueryResult.PageSize;
		this._listener = dataSource;
		this._loadedPages = [];
		this._loadingPages = [];
		
		this._$arr = new Array( pagedQueryResult.TotalRows );
	}
	
	this._loadedPages.push( pagedQueryResult.PageNumber );
	    
	if( this._loadingPages.contains( pagedQueryResult.PageNumber ) )
		this._loadingPages.remove( pagedQueryResult.PageNumber );
	
	if( pagedQueryResult.Result != null )
	{
		for( var i = 0; i < pagedQueryResult.Result.length; ++i )
			this._$arr[ pagedQueryResult.StartIndex + i ] = pagedQueryResult.Result[ i ];
	}
	
	if( pagedQueryResult.PageNumber == 1 )
	{
		this.refresh();
	}
	else
	{
		this.dispatchEvent( new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, CollectionEventKind.ADD ) );
	}
}

PagedDataModel.prototype._checkPage = function()
{
	var page = this._getPageNumber( this._lastEmptyRow );
	
	if( !this._loadedPages.contains( page ) 
		&& this._loadingPages.length < PagedDataModel.PAGE_LOADING_LIMIT 
		&& !this._loadingPages.contains( page ) )
	{
		this._loadingPages.push( page );
	
		if( this._listener != null )
			this._listener.requestQueryPage( this, page );
	}
	
	if( this._maxPagesInMemory > 0 )
	{
		var rightBound = parseInt( page + this._maxPagesInMemory / 2 );
		var leftBound = parseInt( Math.min( page - this._maxPagesInMemory / 2, 1 ) );
		
		for( var enumPageIndex = this._loadedPages.length - 1; enumPageIndex >= 0; --enumPageIndex )
		{
			var currentPage = this._loadedPages[ enumPageIndex ];
			
			if( currentPage < leftBound || currentPage > rightBound)
				this._loadedPages.splice( enumPageIndex, 1 );
		}
	}
}

PagedDataModel.prototype._compare = function( l, r )
{
	if (this.sortField != null )
	{
		l = l[ this.sortField ];
		r = r[ this.sortField ];
	}
	
	result = l == r? 0 : ( l < r? -1 : 1 );
	return this.descending? -result : result;
}

PagedDataModel.prototype.refresh = function()
{
	var p = this;
	this.sort( function ( l, r ) { return p._compare( l, r ); } );
}

PagedDataModel.prototype.get = function( index )
{
	clearTimeout( this._timer );
	var p = this;
	setTimeout( function() { p._checkPage(); }, 500 );
	
	var result = null;
	
	if( index >= 0 && index < this.getLength() )
		result = Collection.prototype.get.call( this, index );
	
	if( result == null )
	{
		this._lastEmptyRow = index;
		
		if( this._defaultRecord == null )
			this._defaultRecord = { _defaultRecordLoadingField: "Loading ..." };
		
		result = _defaultRecord;	
	}
	
	return result;
}

PagedDataModel.prototype._getPageNumber = function( index )
{
	var ps = Math.max( this._pageSize, 1);
	var pageNumber = parseInt( ( index + 1 ) / ps );
	
	if( ( index + 1 ) % ps || pageNumber == 0)
		++pageNumber;
	
	return pageNumber;
}
//	endof PagedDataModel


//	================================================	PagedDataModelAdapter
function PagedDataModelAdapter()
{
	this._pagedDataModel = null;
	this._isLeftExists = false;
	this._isRightExists = false;
	this._currentPage = 0;
	this._pages = new Collection();
	this._pageStart = 0;
	this._pageStop = 0;
	
	this.pageSize = 0;
	this.pagesCount = 10;
	this.totalPages = 0;
}

Utils.setInheritance( PagedDataModelAdapter, Collection );
Utils.setPseudoInheritance( PagedDataModelAdapter, EventDispatcher );

PagedDataModelAdapter.prototype.isLeftExists = function()
{
	return this._isLeftExists;
}

PagedDataModelAdapter.prototype.isRightExists = function()
{
	return this._isRightExists;
}

PagedDataModelAdapter.prototype.getCurrentPage = function()
{
	return this._currentPage;
}
		
PagedDataModelAdapter.prototype.setCurrentPage = function( value )
{
	this._applyPage( value );
}

PagedDataModelAdapter.prototype.getPages = function()
{
	return this._pages;
}

PagedDataModelAdapter.prototype.setModel = function( value )
{
	if( this._pagedDataModel != null )
		this._pagedDataModel.removeEventListener( CollectionEvent.COLLECTION_CHANGE, this._onModelChanged, this );
	
	
	this._pagedDataModel = value;
	
	if( this._pagedDataModel != null )
	{
		this._pagedDataModel.addEventListener( CollectionEvent.COLLECTION_CHANGE, this._onModelChanged, this );
		this._initialize();
		this._applyPage( 1 );
	}
}

PagedDataModelAdapter.prototype.getModel = function()
{
	return this._pagedDataModel;
}

PagedDataModelAdapter.prototype._initialize = function()
{
	if( this._pagedDataModel.getLength() > 0 && pageSize > 0 )
	{				
		totalPages = parseInt( this._pagedDataModel.getLength() / pageSize );
	
		if( this._pagedDataModel.getLength() % pageSize )
			++totalPages;
	}
	else
	{
		totalPages = 0;
	}
	
	this.dispatchEvent( new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, CollectionEventKind.REFRESH ) );
}


PagedDataModelAdapter.prototype.getLength = function()
{
	return pageSize;
}

PagedDataModelAdapter.prototype.get = function( index )
{
	var actualIndex = index + ( ( this._currentPage - 1 ) * pageSize );
	return this._pagedDataModel.get( actualIndex );
}

PagedDataModelAdapter.prototype._onModelChanged = function( event )
{
	if( event.kind == CollectionEventKind.REFRESH )
	{
		this._initialize();
		this._applyPage( 1 );
	}
	else if( event.kind == CollectionEventKind.ADD )
	{
		this.dispatchEvent( new CollectionEvent( CollectionEvent.COLLECTION_CHANGE, CollectionEventKind.ADD ) );
	}
}

PagedDataModelAdapter.prototype._applyPage = function( page )
{
	this._pages.removeAll();
	
	this._currentPage = Math.max( page, 1 );
	this._currentPage = Math.min( this._currentPage, totalPages );
	
	this._isLeftExists = this._currentPage > pagesCount;
	this._isRightExists = this._currentPage < ( totalPages - pagesCount );
	
	if( (this._currentPage % pagesCount) == 0 )
		this._pageStart = Math.max( 1, this._currentPage - pagesCount + 1 );
	else
		this._pageStart = Math.max( 0, this._currentPage - ( this._currentPage % pagesCount ) ) + 1;
	
	this._pageStop = Math.min( this._pageStart + pagesCount, totalPages);
	
	for( var i = this._pageStart; i < this._pageStop; ++i )
		this._pages.push( i );
	
	this.dispatchEvent( new Event( "adapterChange" ) );
	
	this.refresh();
}

PagedDataModelAdapter.prototype.nextPage = function()
{
	this._applyPage( this._currentPage + 1 );
}

PagedDataModelAdapter.prototype.nextPages = function()
{
	this._applyPage( this._pageStart + pagesCount );
}

PagedDataModelAdapter.prototype.previousPage = function()
{
	this._applyPage( this._currentPage - 1 );	
}

PagedDataModelAdapter.prototype.previousPages = function()
{
	this._applyPage( this._currentPage - pagesCount );
}
//	endof PagedDataModelAdapter


//	================================================	Database
function Database()
{
}

Database.prototype.commit = function( unitOfWork, cascade, async )
{
	var remoteObject = this._createRemoteObject();
	
	var dAsync = new DatabaseAsync();
	remoteObject.commit( unitOfWork.extractRelevantObjects( cascade ), dAsync.wrapAsync( async, unitOfWork.extractObjects() ) );
	
	return dAsync;
}

Database.prototype._createRemoteObject = function()
{
	return DataServiceClient.Instance.createRemoteObject( this.getRemoteClassName() );
}

Database.prototype.getRemoteClassName = function()
{
	throw "Not implemented.";
}
//	endof Database


//	================================================	UnitOfWork
function UnitOfWork()
{
	this._affectedObjects = {};
	this._sequence = 0;
	this._operationsCount = 0;
}

Utils.setInheritance( UnitOfWork, EventDispatcher );
UnitOfWork.CREATE = 1;
UnitOfWork.REMOVE = 2;
UnitOfWork.UPDATE = 3;
UnitOfWork.SAVE = 4;

UnitOfWork.prototype.addCreate = function( activeRecord, sequence)
{
	this.register( activeRecord, UnitOfWork.CREATE, sequence);
}

UnitOfWork.prototype.addUpdate = function( activeRecord, sequence)
{
	this.register( activeRecord, UnitOfWork.UPDATE, sequence);
}

UnitOfWork.prototype.addRemove = function( activeRecord, sequence)
{
	this.register( activeRecord, UnitOfWork.REMOVE, sequence);
}

UnitOfWork.prototype.addSave = function( activeRecord, sequence)
{
	this.register( activeRecord, UnitOfWork.SAVE, sequence);
}

UnitOfWork.prototype.register = function( activeRecord, operation, sequence )
{
	var key = activeRecord.ActiveRecordUID;
	
	this._affectedObjects[ key ] = {operation: operation, sequence: this._getSequence( sequence ), activeRecord: activeRecord };
	this._operationsCount++;
	this.dispatchEvent( new Event( "updated" ) );
}

UnitOfWork.prototype.unregister = function( activeRecord )
{
	delete this._affectedObjects[ activeRecord ];
	this._operationsCount--;
	this.dispatchEvent( new Event( "updated" ) );
}

UnitOfWork.prototype._getSequence = function( preferedSequence)
{
	return preferedSequence >= 0? preferedSequence : ++this._sequence;
}

UnitOfWork.prototype.contains = function( activeRecord )
{
	return this._affectedObjects[ activeRecord ] != null;
}

UnitOfWork.prototype.commit = function( cascade, async )
{
	var database = null;
	
	for( var activeRecordKey in this._affectedObjects )
	{
		database = this._affectedObjects[ activeRecordKey ].activeRecord.getDataMapper().getDatabase();
		break;
	}
	
	if( database == null )
		throw "There no commit operations registered.";
	
	var dAsync = database.commit( this, cascade, async );
	dAsync.addResponder( new Responder( this._onResult, this._onFault, this ) );
}

UnitOfWork.prototype._onResult = function( affectedObjects )
{
	for( var activeRecordKey in this._affectedObjects )
	{
		if( this._affectedObjects[ activeRecordKey ].operation == UnitOfWork.REMOVE )
			DataServiceClient.Instance.onDeleted( this._affectedObjects[ activeRecordKey ].activeRecord );
	}

	this._affectedObjects = {};
	
	this.dispatchEvent( new Event( "updated" ) );
	this.dispatchEvent( new UnitOfWorkEvent( UnitOfWorkEvent.COMMIT, affectedObjects ) );
}

UnitOfWork.prototype._onFault = function( faultEvent )
{
	this.dispatchEvent( faultEvent );
}
		
UnitOfWork.prototype.extractRelevantObjects = function( cascade )
{
	var identityMap = new IdentityMap();
	var relevantObjects = [];
	
	for (var activeRecordKey in this._affectedObjects)
	{
		var structure = this._affectedObjects[ activeRecordKey ];
		
		relevantObjects.push(
			{
				operation: structure.operation,
				sequence: structure.sequence,
				activeRecord: structure.activeRecord.prepareToSend( identityMap, cascade )
			} ); 
	}
	
	return relevantObjects;
}

UnitOfWork.prototype.extractObjects = function()
{
	var objects = [];

	for( var activeRecordKey in this._affectedObjects )
		objects.push( this._affectedObjects[ activeRecordKey ].activeRecord );

	return 	objects;
}

UnitOfWork.prototype.isEmpty = function()
{
	return this._operationsCount == 0;
}
//	endof UnitOfWork




//	EVENT CLASSES

//	================================================	Event
function Event(type)
{
	this.type = type || "";
	this.target = null;
}

Event.CHANGED = "changed";
//	endof Event class


//	================================================	DynamicLoadEvent
function DynamicLoadEvent(data)
{
	Event.call(this, DynamicLoadEvent.LOADED);
	this.data = data;
}

Utils.setInheritance(DynamicLoadEvent, Event);

DynamicLoadEvent.LOADED = "loaded";
//	endof DynamicLoadEvent class


//	================================================	PropertyChangeEvent
function PropertyChangeEvent(type, /*kind, */property, oldValue, newValue, source)
{
	Event.call(this, type);
	
//	this.kind = kind;
	this.newValue = newValue;
	this.oldValue = oldValue;
	this.property = property;
	this.source = source;
}

Utils.setInheritance(PropertyChangeEvent, Event);
PropertyChangeEvent.PROPERTY_CHANGE = "propertyChange";
//PropertyChangeEvent.KIND_UPDATE = "update";
//PropertyChangeEvent.KIND_DELETE = "delete";
//	endof PropertyChangeEvent class

//RelationEvent


//	================================================	ActiveRecordEvent
function ActiveRecordEvent( type, activeRecord )
{
	Event.call( this, type );
	this.record = activeRecord;
}

Utils.setInheritance( ActiveRecordEvent, Event );
ActiveRecordEvent.DELETE = "delete";
ActiveRecordEvent.UPDATE = "update";
ActiveRecordEvent.CREATE = "create";
ActiveRecordEvent.RELATION_AFFECTED = "relationAffected";

ActiveRecordEvent.prototype.clone = function()
{
	return new ActiveRecordEvent( this.type, this.record );
}
//	endof ActiveRecordEvent


//	================================================	CollectionEvent
function CollectionEvent( type, kind, location, oldLocation, items )
{
	Event.call( this, type );
	this.kind = kind;
	this.location = location;
	this.oldLocation = oldLocation;
	this.items = items;
}

Utils.setInheritance( CollectionEvent, Event );
CollectionEvent.COLLECTION_CHANGE = "collectionChange";

CollectionEventKind = 
{
	ADD: "add",
	MOVE: "move",
	REFRESH: "refresh",
	REMOVE: "remove",
	REPLACE: "replace",
	RESET: "reset",
	UPDATE: "update"
}
//	endof CollectionEvent


//	================================================	RelationEvent
function RelationEvent( type, relation, activeRecord )
{
	Event.call( this, type );
	this.relation = relation;
	this.activeRecord = activeRecord;
}

Utils.setInheritance( RelationEvent, Event );
RelationEvent.RELATION_ADD = "relationAdd";
RelationEvent.RELATION_DELETE = "relationDelete";
//	endof RelationEvent


//	================================================	PagingEvent
function PagingEvent( pageNumber )
{
	Event.call( this, PagingEvent.PAGE_LOADED );
	this.pageNumber = pageNumber;
}

Utils.setInheritance( PagingEvent, Event );
PagingEvent.PAGE_LOADED = "pageLoaded";
//	endof PagingEvent


//	================================================	UnitOfWorkEvent
function UnitOfWorkEvent()
{
}
//	endof UnitOfWorkEvent


//	================================================	DataServiceMessage
function DataServiceMessage() {}
DataServiceMessage.OPERATION_CREATE = 1;
DataServiceMessage.OPERATION_UPDATE = 2;
DataServiceMessage.OPERATION_DELETE = 3;
//	endof DataServiceMessage


//	================================================	DataServiceClient
function DataServiceClient()
{
	if( DataServiceClient.Instance != null)
		throw "DataServiceClient can not be instantiated.";
		
	EventDispatcher.call(this);

	this._consumer = null;
	this._clientId = null;
	this._handlers = { };
	this._handlers[ DataServiceMessage.OPERATION_CREATE ] = this.onCreated;
	this._handlers[ DataServiceMessage.OPERATION_UPDATE ] = this.onUpdated;
	this._handlers[ DataServiceMessage.OPERATION_DELETE ] = this.onDeleted;
	
	this._remoteObjectCache = {};
}
Utils.setInheritance( DataServiceClient, EventDispatcher );

DataServiceClient.prototype.subscribe = function( clientId )
{
	if( this._consumer != null )
		return;

	this._clientId = clientId;
	
	this._consumer = new Consumer( 
		"DataService", 
		new Async( function(obj) { this.onMessage( obj ); }, function() { }, this ),
		null,
		clientId,
		"DataServiceMessageSelector");
	
	this._consumer.subscribe( null, 
		new Async( 
			function( obj )
			{
				var remote = DataServiceClient.Instance.createRemoteObject( "Weborb.Data.Management.DataServiceClientRegistry" );
				var proxyType = Utils.getClassName( this.proxy );
				
				remote.subscribe( clientId, 
					new Async( 
						function() { __$alert( "Subscribed OK via " + proxyType ); }, 
						function() { alert( "Subscribtion FAILED." ); }
					) 
				);
			}, 
			function() { alert( "Subscribtion FAILED." ); }, 
			this._consumer
		) 
	);
}

DataServiceClient.prototype.onMessage = function( data )
{
	try
	{
		if( data.headers[ "client-id" ] != this._clientId )
		{
			for( var i = 0; i < data.body.length; ++i )
				this._handlers[ data.body[ i ].operation ].call( this, data.body[ i ].activeRecord );
		}
	}
	catch( e ) {}
}

DataServiceClient.prototype.onUpdated = function( activeRecord )
{	
	if( IdentityMap.global.exists( activeRecord.getURI() ) )
	{
		var registeredActiveRecord = IdentityMap.global.extract( activeRecord.getURI() );
		if( !registeredActiveRecord.equals( activeRecord ) )
		{
			__$alert( "Updated: " + activeRecord.getURI() );
			registeredActiveRecord.applyFields( activeRecord );
			this.dispatchEvent( new ActiveRecordEvent( ActiveRecordEvent.UPDATE, registeredActiveRecord ));
		}
	}	
}

DataServiceClient.prototype.onCreated = function( activeRecord, matchQueries)
{	
	activeRecord.clearIsDirty();
	
	var registeredActiveRecord = null;
	
	if( IdentityMap.global.exists( activeRecord.ActiveRecordUID ) )
		registeredActiveRecord = IdentityMap.global.extract( activeRecord.ActiveRecordUID );
	else if( IdentityMap.global.exists( activeRecord.getURI() ) )
		registeredActiveRecord = IdentityMap.global.extract(activeRecord.getURI());
	
	if( registeredActiveRecord == null )
	{
		__$alert( "Created: " + activeRecord.getURI() );
	
		registeredActiveRecord = IdentityMap.global.processUnknownActiveRecord( activeRecord );
		IdentityMap.global.processChilds( activeRecord );
	
		var event = new ActiveRecordEvent( ActiveRecordEvent.CREATE, registeredActiveRecord );
		event.matchQueries = matchQueries;
		
		this.dispatchEvent( event );			
	}
}

DataServiceClient.prototype.onDeleted = function( activeRecord )
{
	if( IdentityMap.global.exists( activeRecord.getURI() ) )
	{
		__$alert( "Removed: " + activeRecord.getURI() );

		var registeredActiveRecord = IdentityMap.global.extract( activeRecord.getURI() );
		var event = new ActiveRecordEvent( ActiveRecordEvent.DELETE, registeredActiveRecord );
		
		registeredActiveRecord.IsDeleted = true;
		IdentityMap.global.remove( activeRecord.getURI() );
		
		this.dispatchEvent( event );
	}
}

DataServiceClient.prototype.createRemoteObject = function( remoteClassName )
{
	var key = remoteClassName + "|" + webOrbURL;
	if( key in this._remoteObjectCache )
		return this._remoteObjectCache[ key ];
	
	__$alert("bind " + remoteClassName + " via " + webOrbURL);

	var proxy = webORB.bind( remoteClassName, webOrbURL );
	this._remoteObjectCache[ key ] = proxy;
	return proxy;
}

DataServiceClient.Instance = new DataServiceClient();
//	endof DataServiceClient






//	INIT SECTION ======================
webORB.registerTypeFactory("Weborb.Data.Management.QueryResult", function(object)
{
	var qr = new QueryResult();
	Utils.copyValues(object, qr);
	return qr;
} );





//	DEBUG FUNCTIONS ======================
function __$showObject(o, text, showValues, hideFunctions)
{
	if (!__$debug)
		return;
	
	var s = "{\n";
	if (o == null)
		s = "{}";
	else if (typeof(o) != "object")
		s = o.toString();
	else
	{
		for (var m in o)
		{
			try
			{
				if (o[m] instanceof Function && hideFunctions)
					continue;

				s += "\t" + m;
				if (o[m] instanceof Function)
					s += " :Function";
				else if (showValues)
				{
					s += ": ";
					s += (o[m] instanceof Array)? "[" + o[m] + "]" : o[m];
				}
				s += "\n";
			}
			catch (e) {}
		}
		s += "}"
	}
	
	if( text != null )
		s = text + " :" + Utils.getClassName(o) + "\n" + s;
	if( !__$alert( s ) )
		return s;
}

function __$alert(msg)
{
	if (!__$debug)
		return true;
	if ( window["userAlert"] instanceof Function )
	{
		userAlert(msg);
		return true;
	}
}
