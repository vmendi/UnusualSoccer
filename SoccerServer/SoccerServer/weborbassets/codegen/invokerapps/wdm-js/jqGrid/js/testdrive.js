var adapter, tableList, 
	divNewRecord, divNewRecordCaption, divNewRecordContent, 
	divCode, divCodeContent, 
	divGrid, 
	divPager, codeText, lstPageSize;

function init()
{
	adapter = new JqAdapter( "grid", "divPager" );
	tableList = document.getElementById( "tableList" );
	
	divNewRecord = document.getElementById( "divNewRecord" );
	divNewRecordCaption = document.getElementById("divNewRecordCaption");
	divNewRecordContent = document.getElementById( "divNewRecordContent" );
	
	divCode = document.getElementById( "divCode" );
	divCodeContent = document.getElementById( "divCodeContent" );
	
	divGrid = document.getElementById( "divGrid" );
	
	codeText = divCodeContent.innerHTML;
	divPager = document.getElementById( "divPager" );
	lstPageSize = document.getElementById( "lstPageSize" );

	var listHtml = "";
	for (var n in ActiveRecords)
	{
		if ( ActiveRecords[n] instanceof DataMapper )
			listHtml += "<div onclick=\"switchTable('" + n + "', this);\">" + n + "</div>";
	}
	
	tableList.innerHTML = listHtml;
}

var selectedTableDiv = null;
function switchTable(tabName, div)
{
	if (selectedTableDiv)
		selectedTableDiv.className = "";
	
	(selectedTableDiv = div).className = "ui-state-hover";
	
	adapter.selectTable( tabName, lstPageSize.value );
	switchToGrid();
}

function page( pageNo )
{
	adapter.showPage( pageNo );
}

//	=============================	JqAdapter
function JqAdapter( gridId, pagerId )
{
	this.dateFormat = "m/d/Y";
	
	this.gridId = "#" + gridId;
	this._pagerElement = document.getElementById( pagerId );
	this._dataMapper = null;
	this.activeRecord = null;
	this.lastEditedId = null;
	this.editedRowsData = {};
	this.selectedTable = null;
	this.shownPageNo = 0;
	this._pageSize = 20;
	this._lastPageSize = 20;
	this._activeCollection = null;
	this._needReload = false;
	this._dontEdit = false;	// use it ONLY when you make row editing onSelectRow
	
	DataServiceClient.Instance.subscribe( __clientId__ );
	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.DELETE, this._onSyncDelete, this );
	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.UPDATE, this._onSyncUpdate, this );
	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.CREATE, this._onSyncCreate, this );
}

JqAdapter.prototype.publish = function( dataObject )
{
	this._activeCollection = null;
	
	var data = dataObject instanceof QueryResult? dataObject.Result : dataObject;
	if (data instanceof Array )
	{
		data = Collection.fromObject( data );
		data._pageSize = this._pageSize;
	}
	
	this._activeCollection = data;
	this._buildPager();

	//	check if page exists
	var startNdx = this.shownPageNo == 0? 0 : (this.shownPageNo - 1 ) * this._activeCollection._pageSize;
	var endNdx = this.shownPageNo == 0? this._activeCollection.getLength() : Math.min( this._activeCollection.getLength(), startNdx + this._activeCollection._pageSize);
	var rec = data.get( startNdx );
	
	if( rec == null )
		this._activeCollection.removeItemAt( startNdx );
	
	if( this.shownPageNo > 1 && ( rec == null || endNdx - startNdx == 0 ) )
	{
		this.showPage( this.shownPageNo - 1 );
		return;
	}
	
	//	build columns model
	var colNames = [ "", "" ];
	var colModel = [ 
		{ name: "", index: "_save_", formatter: JqAdapter._formatterSaveButton, editable: false, sortable: false, width: 56, align: "center", fixed: true },
		{ name: "", index: "_delete_", formatter: JqAdapter._formatterDeleteButton, editable: false, sortable: false, width: 71, align: "center", fixed: true } ];
	var gridData = [];
	
	var columnsInfo = this.activeRecord.getColumnsInfo();
	for( var i = 0; i < columnsInfo.length; ++i )
	{
		var colInfo = columnsInfo[i];
		colNames.push( colInfo.name );
		
		var cm =  { 
			name: colInfo.name, 
			index: colInfo.name, 
			sorttype: this._getSortType( colInfo ), 
			formatter: this._getFormatter( colInfo ), 
			editrules: this._getEditRules( colInfo ), 
			editable: !colInfo.isPK, 
			align: colInfo.type == "int" || colInfo.type == "float"? "right" : "left",
			width: 80,
			sortable: false,
			formatoptions: { }
			};
		if( cm.formatter == "date" )
		{
			cm.datefmt = this.dateFormat;
			cm.formatoptions.newformat = this.dateFormat;
		}
			
		colModel.push( cm );
	}
	
	//	fill gridData array
	for( var i = startNdx; i < endNdx; ++i )
		gridData.push( this._activeCollection.get( i ) );
		
	//	recreate grid
	var pThis = this;
	
	$( this.gridId ).GridUnload();
	$( this.gridId ).jqGrid(
	  {
	    datatype: "local",
	    data: gridData,
	    colNames: colNames,
	    colModel: colModel,
	    rowNum: endNdx - startNdx,
		altRows: false,
	    caption: Utils.getClassName( this.activeRecord ) + "s",
		
		cellEdit: false,
		editurl: "clientArray",
		cellsubmit: "clientArray",
		
		width: 780,
		height: 300,
		
		onSelectRow: this._createMethodPointer( "editRecord" ),
		onPaging: this._createMethodPointer( "_onPaging" )
	  }
	);
}

JqAdapter.prototype._getSortType = function( colInfo )
{
	if( colInfo.type == "string" )
		return "text";
	if( colInfo.type == "boolean" )
		return "int";
	return colInfo.type;
}

JqAdapter.prototype._getFormatter = function( colInfo )
{
	if( colInfo.type == "int" )
		return "integer";
	if( colInfo.type == "float" )
		return "number";
	if( colInfo.type == "date" )
		return "date";
	if( colInfo.type == "boolean" )
		return "checkbox";
	return null;
}

JqAdapter.prototype._getEditRules = function( colInfo )
{
	return result = { 
		required: colInfo.isRequired, 
		integer: colInfo.type == "int", 
		number: colInfo.type == "float", 
		date: colInfo.type == "date"
		};
}

JqAdapter._formatterSaveButton = function( cellvalue, options, rowObject )
{
   return cellvalue || ( "<button id='_save_" + options.rowId + "' class='ui-state-default cellButton' disabled style='color:#ccc' onclick='adapter._disableBtn( this ); adapter.updateRecord(\"" + options.rowId + "\"); adapter._dontEdit = true;'>Save</button>" );
}

JqAdapter._formatterDeleteButton = function( cellvalue, options, rowObject )
{
   return "<button class='ui-state-default cellButton' onclick='adapter.deleteRecord(\"" + options.rowId + "\"); adapter._dontEdit = true;'>Delete</button>";
}

JqAdapter.prototype._disableBtn = function( btn )
{
	btn.disabled = true;
	btn.style.color = "#ccc";
}

JqAdapter.prototype._enableBtn = function( btn )
{
	btn.disabled = false;
	btn.style.color = "#2e6e9e";
}

JqAdapter.prototype._createMethodPointer = function( funcName )
{
	var pThis = this;
	return function() { pThis[funcName].apply( pThis, arguments ); };
}

JqAdapter.prototype._buildPager = function()
{
	var s = "";
	if( this._activeCollection._pageSize > 0 && this._activeCollection._pageSize < this._activeCollection.getLength() )
	{
		for (var i = 1; i <= Math.ceil( this._activeCollection.getLength() / this._activeCollection._pageSize ); ++i )
		{
			s += i == this.shownPageNo? 
				"<span class=\"current-page\">" + i.toString() + "</span>"
				: "<a href='javascript:page(" + i + ")'>" + i + "</a>";
			s += " &nbsp; ";
		}
	}
	else
		s = "&nbsp;"
	
	this._pagerElement.innerHTML = s;
}

JqAdapter.prototype._onUpdateRecordFailed = function( rowId, err )
{
	$( this.gridId ).setRowData( rowId, this.editedRowsData[ rowId ] ); 
	delete this.editedRowsData[ rowId ];
	alert( "Error saving record: " + err.description );
}

JqAdapter.prototype.selectTable = function( tableName, pageSize )
{
	if( !pageSize )
		pageSize = this._lastPageSize;
	else
		this._lastPageSize = pageSize;
	
	this._pageSize = pageSize;

	this._dataMapper = ActiveRecords[ tableName ];
	this.activeRecord = this._dataMapper.createActiveRecordInstance();
	this.selectedTable = tableName;
	
	this.shownPageNo = 1;
	try { $( this.gridId )[0].innerHTML = "Loading..."; }
	catch(e) {}
	this._pagerElement.innerHTML = "";

	this._activeCollection = this._dataMapper.findAll( { PageSize: parseInt( this._pageSize ) } );
	this._activeCollection.addEventListener( DynamicLoadEvent.LOADED, this._onLoadSync, this );
	this._activeCollection.addEventListener( CollectionEvent.COLLECTION_CHANGE, this._onLoadSync, this );
}

JqAdapter.prototype._onLoadSync = function( event )
{
	this.publish( event.target );
}

JqAdapter.prototype.showPage = function( pageNo )
{
	if( this.shownPageNo <= 0 )
		return;
	
	if( this._needReload )
	{
		this._activeCollection.clear();
		this._needReload = false;
	}
	
	this.shownPageNo = pageNo;
	var rec = this._activeCollection.get( (pageNo - 1) * this._activeCollection._pageSize );
	if( rec == null || rec.getIsLoaded() )
		this.publish( this._activeCollection );
}

JqAdapter.prototype._onAfterRestoreRow = function( rowId )
{
	var self = this;
	setTimeout( function() { self._resetRow( rowId ) }, 50 );
}

JqAdapter.prototype.editRecord = function( rowId )
{
	if( this._dontEdit )
	{
		this._dontEdit = false;
		return;
	}

	if( rowId && rowId != this.lastEditedId )
	{
		if( this.lastEditedId != null )
			$( this.gridId ).restoreRow( this.lastEditedId, this._createMethodPointer( "_onAfterRestoreRow" ) ); 
		
		this.lastEditedId = rowId;
 	}
	
	if( this.editedRowsData[ rowId ] == null )
		this.editedRowsData[ rowId ] = $( this.gridId ).getRowData( rowId );
	
	$( this.gridId ).editRow( rowId, true, null,
		null, "clientArray", null, 
		this._createMethodPointer( "updateRecord" ),
		null, this._createMethodPointer( "_onAfterRestoreRow" )
	);
	
	this._enableBtn( document.getElementById( "_save_" + this.lastEditedId ) );
}

JqAdapter.prototype.getRecord = function( rowId )
{
	var cells = $( this.gridId ).getRowData( rowId );
	var rec = this._dataMapper.createActiveRecordInstance();
	
	Utils.copyValues( cells, rec );
	return rec;
}

JqAdapter.prototype.updateRecord = function( rowId )
{
	if( !$( this.gridId ).saveRow( rowId ) )
		return;
	
	var record = this.getRecord( rowId );
	var trueRecord = IdentityMap.global.extract( record.getURI() );
	Utils.copyValues( record, trueRecord );
	trueRecord.save(
		new Async( 
			function() { delete this.editedRowsData[ rowId ]; }, 
			function( err ) { this._onUpdateRecordFailed( rowId, err ); }, 
			this 
			)
	);
	
	return true;
}

JqAdapter.prototype.deleteRecord = function( rowId )
{
	$( this.gridId ).restoreRow( rowId );
	
	var record = this.getRecord( rowId );
	record.remove(
		new Async( 
			function() { $( this.gridId ).delRowData( rowId ); this.selectTable( this.selectedTable ); },
			function(err) { alert( "Error deleting record: " + err.description ); }, 
			this
			) 
	);
}

JqAdapter.prototype.addRecord = function( record, okFunc, errFunc )
{
	var activeRec = this._dataMapper.createActiveRecordInstance();
	Utils.copyValues( record, activeRec );
	
	activeRec.create(
		new Async( 
			function( rec )
			{
				this.selectTable( this.selectedTable ); 
				if( okFunc instanceof Function ) okFunc(); 
			},
			function(err) 
			{
				alert( "Error adding record: " + err.description );
				if( errFunc instanceof Function ) errFunc();
			},
			this
		) 
	);
}

JqAdapter.prototype._resetRow = function( rowId )
{
	this._disableBtn( document.getElementById( "_save_" + rowId ) );

	var gridRec = this.getRecord( rowId );
	var curRec = IdentityMap.global.extract( gridRec.getURI() );
	
	if( curRec == null || gridRec.equals( curRec ) )
		return;
	
	var columnsInfo = curRec.getColumnsInfo();
	for( var i = 0; i < columnsInfo.length; ++i )
	{
		var value = curRec[ columnsInfo[ i ].name ];
		if( columnsInfo[ i ].type == "date" )
		{
			var mf = {};
			Utils.copyMembers( jQuery.jgrid.formatter.date, mf );
			mf.masks = { myFormat: this.dateFormat };
			value = $.fmatter.util.DateFormat( jQuery.jgrid.formatter.date, value, "myFormat", mf );
		}
		
		$( this.gridId ).setCell( rowId, i + 2, value );
	}
}


//	synchronization handlers
JqAdapter.prototype._onSyncDelete = function(ev)
{
	if( this._dataMapper == null )
		return;

	if( ev.record.getRemoteClassName() == this._dataMapper.createActiveRecordInstance().getRemoteClassName() )
		this._needReload = true;

	for( var i = 1; i <= $( this.gridId ).getDataIDs().length; ++i )
	{
		var gridRec = this.getRecord( i );
		if( gridRec.getURI() == ev.record.getURI() )
		{
			$( this.gridId ).restoreRow( i );
			$( this.gridId ).setCell( i, 0, "DELETED", "deleted", { colspan: gridRec.getColumnsInfo().length + 2 } );
		}
	}
}

JqAdapter.prototype._onSyncUpdate = function(ev)
{
	if( this._dataMapper == null )
		return;
	
	for( var i = 1; i <= $( this.gridId ).getDataIDs().length; ++i )
	{
		var gridRec = this.getRecord( i );
		if( gridRec.getURI() == ev.record.getURI() )
		{
			if( document.getElementById( "_save_" + i ).disabled )
				this._resetRow( i );
		}
	}
}

JqAdapter.prototype._onSyncCreate = function(ev)
{
	if( this._dataMapper == null )
		return;
	
	if( ev.record.getRemoteClassName() == this._dataMapper.createActiveRecordInstance().getRemoteClassName() )
		this._needReload = true;
}
//	endof JqAdapter



//	=============================	Creating new record and showing code functions
function addRecord()
{
	if( adapter.activeRecord == null )
	{
		alert("Select a table first.");
		return;
	}
	
	if( divNewRecord.style.display == "block" )
		return;
	
	var columnInfos = adapter.activeRecord.getColumnsInfo();
	var strHtml = "<form name='newRec' onsubmit='return false'><table class='newRec'>";
	
	for( var i = 0; i < adapter.activeRecord.getColumnsInfo().length; ++i )
	{
		var colInfo = adapter.activeRecord.getColumnsInfo()[i];
		strHtml += "<tr><td class='cb'>" + colInfo.name + "</td> <td><input name='__" + colInfo.name + "'";
		if( columnInfos[i].isPK )
		{
			strHtml += " disabled";
			if( columnInfos[i].type == "int" )
				strHtml += " value='0'";
		}
		strHtml += "></td></tr>"
	}
	
	strHtml += "</table><br><button class='ui-state-default marged ptr' onclick='onAddRecordClick()'>Add</button> <button class='ui-state-default marged ptr' onclick='onCancelAddRecordClick()'>Cancel</button></form>";
	divNewRecordContent.innerHTML = strHtml;
	
	divNewRecordCaption.innerHTML = "New " + Utils.getClassName( adapter.activeRecord );
	
	divGrid.style.display = divPager.style.display = divCode.style.display = "none";
	divNewRecord.style.display = "block";
}

function onAddRecordClick()
{
	var row = {};
	var els = document.forms["newRec"].elements;
	
	for( var i = 0; i < els.length; ++i )
	{
		var colName = els[i].name.substr(2);
		row[ colName ] = els[i].value;
	}
	
	adapter.addRecord( row, switchToGrid, null );
}

function onCancelAddRecordClick()
{
	switchToGrid();
}

function switchToGrid()
{
	divNewRecordContent.innerHTML = "";
	divNewRecord.style.display = divCode.style.display = "none";
	divGrid.style.display = divPager.style.display = "block";
}

function showCode()
{
	if( adapter.activeRecord == null )
	{
		alert("Select a table first.");
		return;
	}
	
	var table = Utils.getClassName( adapter.activeRecord );
	var tableVar = table.charAt( 0 ).toLowerCase() + table.substr( 1 );
	var pk, pkValue, field, fieldValue, setFields = "";
	
	var columnsInfo = adapter.activeRecord.getColumnsInfo();
	for( var i = 0; i < columnsInfo.length; ++i )
	{
		if( columnsInfo[i].isPK )
		{
			pk = columnsInfo[i].name;
			pkValue = getRandomValue( columnsInfo[i].type );
		}
		else
		{
			if( field == null )
			{
				field = columnsInfo[i].name;
				fieldValue = getRandomValue( columnsInfo[i].type );
			}
			setFields += tableVar + "." + columnsInfo[i].name + " = " + getRandomValue( columnsInfo[i].type ) + ";\n";
		}
	}
	divCodeContent.innerHTML = codeText.replace( /%Table%/g, table ).replace( /%tableVar%/g, tableVar )
		.replace( /%pk%/g, pk ).replace( /%pkValue%/g, pkValue ).replace( /%field%/g, field ).replace( /%fieldValue%/g, fieldValue ).replace( /%setFields%/g, setFields );

	divGrid.style.display = divPager.style.display = divNewRecord.style.display = "none";
	divCode.style.display = "block";
	
	divCodeContent.scrollTop = 0;
}

function getRandomValue( typeName )
{
	switch( typeName )
	{
		case "int": return parseInt(Math.random() * 10000);
		case "float": return Math.random() * 10000;
		case "date": return "\"06/11/2009\"";
		case "boolean": return 1;
		case "string": return "\"TEST VALUE\"";
	}
}
//	endof Creating new record and showing code functions

