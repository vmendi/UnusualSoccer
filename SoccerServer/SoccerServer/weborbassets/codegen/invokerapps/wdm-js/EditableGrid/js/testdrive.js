var adapter, tableList, 
	divNewRecord, divNewRecordCaption, divNewRecordContent, 
	divCode, divCodeContent, 
	divGridBlock, divGrid, divPager, codeText, lstPageSize,
	selectedTableDiv;

function init()
{
	adapter = new EgAdapter( "divGrid", "divPager", "divGridCaption" );
	tableList = document.getElementById( "tableList" );

	divNewRecord = document.getElementById( "divNewRecord" );
	divNewRecordCaption = document.getElementById("divNewRecordCaption");
	divNewRecordContent = document.getElementById( "divNewRecordContent" );

	divCode = document.getElementById( "divCode" );
	divCodeContent = document.getElementById( "divCodeContent" );

	divGridBlock = document.getElementById( "divGridBlock" );
	divGrid = document.getElementById( "divGrid" );
	divPager = document.getElementById( "divPager" );
	codeText = divCodeContent.innerHTML;
	lstPageSize = document.getElementById( "lstPageSize" );

	var listHtml = "";
	for ( var n in ActiveRecords )
	{
		if ( ActiveRecords[ n ] instanceof DataMapper )
			listHtml += "<div onclick=\"switchTable('" + n + "', this);\">" + n + "</div>";
	}
	
	tableList.innerHTML = listHtml;
}

function switchTable( tabName, div )
{
	if ( selectedTableDiv )
		selectedTableDiv.className = "";
	
	(selectedTableDiv = div).className = "selectedLi";
	
	adapter.selectTable( tabName, lstPageSize.value );
	switchToGrid();
}

function getDateString( value )
{
	if( !( value instanceof Date ) )
		return value;
	
	return ( value.getMonth() + 1 ) + "/" + value.getDate() + "/" + value.getFullYear();
}

function parseDateString( value )
{
	if( value instanceof Date )
		return value;
	
	var parts = value.split( "/" );
	var date = new Date( parseInt( parts[ 2 ] ), parseInt( parts[ 0 ] ) - 1, parseInt( parts[ 1 ] ) );
	return date;
}

function page( pageNo )
{
	adapter.showPage( pageNo );
}

//	=============================	Renderer classes
function USDateCellRenderer( config ) { DateCellRenderer.call( this, config ); }
Utils.setInheritance( USDateCellRenderer, DateCellRenderer );

USDateCellRenderer.prototype.render = function( cell, value ) 
{
	if( value instanceof Date )
		cell.innerHTML = getDateString( value );
	else
	{
		var date = this.editablegrid.checkDate( value );
		if( typeof date == "object" ) 
			cell.innerHTML = getDateString( new Date( date.sortDate ) );
		else 
			cell.innerHTML = value;
	}
};

function SaveCellRenderer() { CellRenderer.call( this ); }
Utils.setInheritance( SaveCellRenderer, CellRenderer );
SaveCellRenderer.prototype.render = function( cell, value )
{
	CellRenderer.prototype.render.call(this, cell, value );
	cell.style.width = "1%";
	cell.innerHTML = "<button class=\"cellButton\" style=\"color:#ccc\" id=\"_save_" + cell.rowIndex + "\" onclick=\"this.disabled = true; this.style.color = '#ccc'; adapter.updateRecord(" + cell.rowIndex + ");\" disabled>Save</button>";
}

function DeleteCellRenderer() { CellRenderer.call( this ); }
Utils.setInheritance( DeleteCellRenderer, CellRenderer );
DeleteCellRenderer.prototype.render = function( cell, value )
{
	CellRenderer.prototype.render.call(this, cell, value );
	cell.style.width = "1%";
	cell.innerHTML = "<button class=\"cellButton\" onclick=\"adapter.deleteRecord(" + cell.rowIndex + ");\">Delete</button>";
}
//	endof Renderer classes


//	=============================	Editor classes
function DateCellEditor( size, maxlen, config ) { TextCellEditor.call( size, maxlen, config ); }
Utils.setInheritance( DateCellEditor, TextCellEditor );

DateCellEditor.prototype.editorValue = DateCellEditor.prototype.formatValue = function( value )
{
	return value instanceof Date? getDateString( value ) : value.toString();
}
//	endof Editor classes


//	=============================	extend several EditableGrid functions
var extendEditableGridFunctions = function()
{
	//	extend CellEditor.applyEditing
	var pf1 = CellEditor.prototype.applyEditing;
	CellEditor.prototype.applyEditing = function( element, newValue ) 
	{
		var isError = false;
		
		if( element && element.isEditing && !this.column.isValid( newValue ) ) 
		{
			alert( "Invalid value: " + newValue );
			this.cancelEditing( element );
			this._clearEditor(element);
			isError = true;
		}
		
		if( !isError )
			pf1.call( this, element, newValue );
		
		var isDirty = adapter.isRowDirty( element.rowIndex );
		( btn = document.getElementById( "_save_" + element.rowIndex ) ).disabled = !isDirty;
		btn.style.color = isDirty? "#2e6e9e" : "#ccc";

		if( isError )
			return false;
	}
}();
//	endof extend several EditableGrid functions



//	=============================	EgAdapter
function EgAdapter( gridId, pagerId, captionId )
{
	this._gridElement = document.getElementById( gridId );
	this._pagerElement = document.getElementById( pagerId );
	this._captionElement = document.getElementById( captionId );
	this._dataMapper = null;
	this.activeRecord = null;
	this.selectedTable = null;
	this.shownPageNo = 0;
	this._pageSize = 20;
	this._lastPageSize = 20;
	this._activeCollection = null;
	this._needReload = false;
	
	DataServiceClient.Instance.subscribe( __clientId__ );
	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.DELETE, this._onSyncDelete, this );
	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.UPDATE, this._onSyncUpdate, this );
	DataServiceClient.Instance.addEventListener( ActiveRecordEvent.CREATE, this._onSyncCreate, this );
}

EgAdapter.prototype.publish = function( dataObject )
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
	
	//	build grid
	this.grid = new EditableGrid(
		"DemoGrid", 
		{
			enableSort: false, // true is the default, set it to false if you don't want sorting to be enabled
			editmode: "absolute", // change this to "fixed" to test out editorzone, and to "static" to get the old-school mode
			editorzoneid: "edition", // will be used only if editmode is set to "fixed"
			checkDate: function( strDate, strDatestyle ) 
			{
				strDatestyle = strDatestyle || "US";
				if( strDate instanceof Date )
					strDate = getDateString( strDate );
				
				return EditableGrid.prototype.checkDate.call( this, strDate, strDatestyle );
			}
		}
	);
	
	//var headRenderer = new MyHeaderRenderer();

	this._addColumn( "_save_", "", "html", false );
	this._addColumn( "_delete_", "", "html", false );
	this.grid.setCellRenderer( "_save_", new SaveCellRenderer() );
	this.grid.setCellRenderer( "_delete_", new DeleteCellRenderer() );
	//this.grid.setHeaderRenderer( "_save_", headRenderer );
	//this.grid.setHeaderRenderer( "_delete_", headRenderer );

	
	this.columnsInfo = this.activeRecord.getColumnsInfo();
	
	for( var i = 0; i < this.columnsInfo.length; ++i )
	{
		this._addColumn( this.columnsInfo[ i ] );
		//this.grid.setHeaderRenderer( i + 2, headRenderer );
	}
	
	this.grid.renderGrid( this._gridElement.id, "tabGrid", "tabGrid" );

	//	fill grid
	for( var i = startNdx; i < endNdx; ++i )
		this.grid.addRow( i, this._activeCollection.get( i ), true );
}

EgAdapter.prototype.restoreRow = function( rowIndex, grid )
{
	//	if the grid was recreated during asynchronous call, do nothing
	if( this.grid != grid )
		return false;
	
	var rec = this._getCollectionRecord( rowIndex );
	
	for( var i = 0; i < this.columnsInfo.length; ++i )
		this.grid.setValueAt( rowIndex, i + 2, rec[ this.columnsInfo[ i ].name ] );
	
	return true;
}

EgAdapter.prototype._addColumn = function( colInfoOrName, label, dataType, editable )
{
	var col = new Column();
	
	if( colInfoOrName instanceof ColumnInfo )
	{
		col.name = col.label = colInfoOrName.name;
		col.datatype = this._getDataType( colInfoOrName );
		col.editable = !colInfoOrName.isPK;
	}
	else
	{
		col.name = colInfoOrName;
		col.label = label;
		col.datatype = dataType;
		col.editable = editable;
	}
	
	this.grid.parseColumnType( col );
	
	// create suited cell renderer
	this.grid._createCellRenderer( col );
	this.grid._createHeaderRenderer( col );
	
	// create suited cell editor
	this.grid._createCellEditor( col );
	this.grid._createHeaderEditor( col );
	
	if( col.datatype == "date" )
	{
		col.cellRenderer = new USDateCellRenderer();
		col.cellRenderer.editablegrid = this.grid;
		col.cellRenderer.column = col;
		
		col.cellEditor = new DateCellEditor();
		col.cellEditor.editablegrid = this.grid;
		col.cellEditor.column = col;
	}
	// add default cell validators based on the column type
	this.grid._addDefaultCellValidators( col );

	col.editablegrid = this.grid;
	this.grid.columns.push( col );
}

EgAdapter.prototype._getDataType = function( colInfo )
{
	if( colInfo.type == "int" )
		return "integer";
	else if( colInfo.type == "float" )
		return "double";
	return colInfo.type;
}

EgAdapter.prototype._buildPager = function()
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

EgAdapter.prototype._onUpdateRecordFailed = function( rowId, err, grid )
{
	this.restoreRow( rowId, grid );
	alert( "Error saving record: " + err.description );
}

EgAdapter.prototype.selectTable = function( tableName, pageSize )
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
	this._captionElement.innerHTML = Utils.getClassName( this.activeRecord ) + "s";
	this._gridElement.innerHTML = "Loading...";
	this._pagerElement.innerHTML = "";
	
	this._activeCollection = this._dataMapper.findAll( { PageSize: parseInt( this._pageSize ) } );
	this._activeCollection.addEventListener( DynamicLoadEvent.LOADED, this._onLoadSync, this );
	this._activeCollection.addEventListener( CollectionEvent.COLLECTION_CHANGE, this._onLoadSync, this );
}

EgAdapter.prototype._onLoadSync = function( event )
{
	this.publish( event.target );
}

EgAdapter.prototype.showPage = function( pageNo )
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

EgAdapter.prototype.getRecord = function( rowId )
{
	var rec = this._dataMapper.createActiveRecordInstance();
	
	for( var i = 0; i < this.columnsInfo.length; ++i )
	{
		var colInfo = this.columnsInfo[ i ];
		var value = this.grid.getValueAt( rowId, i + 2 );
		if( colInfo.type == "date" )
		{
			//	use the date as UTC date
			var d = parseDateString( value );
			rec[ colInfo.name ] = new Date( d.getTime() - d.getTimezoneOffset() * 60000 );
		}
		else
			rec[ colInfo.name ] = value;
	}
	return rec;
}

EgAdapter.prototype.isRowDirty = function( rowId )
{
	var actRec = this._getCollectionRecord( rowId );
	
	for( var i = 0; i < this.columnsInfo.length; ++i )
	{
		var colInfo = this.columnsInfo[ i ];
		var value = this.grid.getValueAt( rowId, i + 2 );
		var recValue = actRec[ colInfo.name ];
		
		if( colInfo.type == "date" )
			value = getDateString( parseDateString( value ) );
		if( recValue instanceof Date )
			recValue = getDateString( recValue );

		if( value != recValue )
			return true;
	}
	
	return false;
}

EgAdapter.prototype._getCollectionRecord = function( rowId )
{
	var ndx = (this.shownPageNo - 1) * parseInt( this._activeCollection._pageSize ) + parseInt( rowId );
	return this._activeCollection.get( ndx );
}

EgAdapter.prototype.updateRecord = function( rowId )
{
	var record = this.getRecord( rowId );
	var collectionRecord = this._getCollectionRecord( rowId );
	
	record.save(
		new Async( 
			function() { Utils.copyValues( record, collectionRecord ) }, 
			function( err ) { this._onUpdateRecordFailed( rowId, err, this.grid ); }, 
			this 
			)
	);
	
	return true;
}

EgAdapter.prototype.deleteRecord = function( rowId )
{
	var record = this._getCollectionRecord( rowId );
	record.remove(
		new Async( 
			function() { this.selectTable( this.selectedTable ); },
			function(err) { alert( "Error deleting record: " + err.description ); }, 
			this
			) 
	);
}

EgAdapter.prototype.addRecord = function( record, okFunc, errFunc )
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

//	synchronization handlers
EgAdapter.prototype._onSyncDelete = function(ev)
{
	if( this._dataMapper == null )
		return;
	
	if( ev.record.getRemoteClassName() == this._dataMapper.createActiveRecordInstance().getRemoteClassName() )
		this._needReload = true;

	for( var i = 0; i < this.grid.getRowCount(); ++i )
	{
		var gridRec = this.getRecord( i );
		if( gridRec.getURI() == ev.record.getURI() )
		{
			var tr = this.grid.getRow( i );
			tr.innerHTML = "<td colspan='" + ( this.columnsInfo.length + 2 ) + "' class='deleted'>DELETED</td>";
		}
	}
}

EgAdapter.prototype._onSyncUpdate = function(ev)
{
	if( this._dataMapper == null )
		return;
	
	for( var i = 0; i < this.grid.getRowCount(); ++i )
	{
		var gridRec = this.getRecord( i );
		if( gridRec.getURI() == ev.record.getURI() )
		{
			if( document.getElementById( "_save_" + i ).disabled )
			{
				for( var j = 0; j < this.columnsInfo.length; ++j )
				{
					if( this.grid.getCell( i, j + 2 ).isEditing )
						return;
				}
				for( var j = 0; j < this.columnsInfo.length; ++j )
					this.grid.setValueAt( i, j + 2, ev.record[ this.columnsInfo[ j ].name ] );
			}
		}
	}
}

EgAdapter.prototype._onSyncCreate = function(ev)
{
	if( this._dataMapper == null )
		return;
	
	if( ev.record.getRemoteClassName() == this._dataMapper.createActiveRecordInstance().getRemoteClassName() )
		this._needReload = true;
}
//	endof EgAdapter




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
	
	strHtml += "</table><br><button class='borderTwin marged ptr' onclick='onAddRecordClick()'>Add</button> <button class='borderTwin marged ptr' onclick='onCancelAddRecordClick()'>Cancel</button></form>";
	divNewRecordContent.innerHTML = strHtml;
	
	divNewRecordCaption.innerHTML = "New " + Utils.getClassName( adapter.activeRecord );
	
	divGridBlock.style.display = divPager.style.display = divCode.style.display = "none";
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
	divGridBlock.style.display = divPager.style.display = "block";
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

	divGridBlock.style.display = divPager.style.display = divNewRecord.style.display = "none";
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
