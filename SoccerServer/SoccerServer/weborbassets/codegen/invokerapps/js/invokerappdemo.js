var arrayIDCounter = 0;
var responseRowCounter = 0;


function generateSource()
{
    var methodSelector = document.getElementById('availableSignatures'); 
    var selectedMethod = methodInfo[ methodSelector.selectedIndex - 1 ];
    
var code = "&lt;html&gt;<br\>" +
"&nbsp;&lt;head&gt;<br\>" +
"&nbsp;&nbsp;&lt;script src=\"scripts/WebORB.js\" type=\"text/javascript\"&gt;&lt;/script&gt;<br\>" +
"&nbsp;&nbsp;&lt;script src=\"scripts/" + serviceScriptPath + "\" type=\"text/javascript\"&gt;&lt;/script&gt;<br\>" +
"&nbsp;&nbsp;&lt;script type=\"text/javascript\"&gt;<br\>" + 
"&nbsp;&nbsp;&nbsp;var service;<br\><br\>" + 
"&nbsp;&nbsp;&nbsp;function initService()<br\>" + 
"&nbsp;&nbsp;&nbsp;{<br\>" + 
"&nbsp;&nbsp;&nbsp;&nbsp;service = new " +  serviceClass + "();<br\>" + 
"&nbsp;&nbsp;&nbsp;}<br\><br\>" + 
"&nbsp;&nbsp;&nbsp;function doInvoke()<br\>" + 
"&nbsp;&nbsp;&nbsp;{<br\>";

for ( var i = 0; i < selectedMethod.args.length; i++) 
	code += valueToCode( "arg" + i, selectedMethod.argModel[ "arg" + i ] ) + "<br/>";

code += "&nbsp;&nbsp;&nbsp;&nbsp;try<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;{<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;var result = service." + selectedMethod.name + "( ";

for ( var i = 0; i < selectedMethod.args.length; i++) 
{
	code += "arg" + i;
	
	if( i != selectedMethod.args.length - 1 )
		code += ", ";
}

code +=" );<br\>" + 
"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;alert( \"Received result - \" + result );<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;}<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;catch( err )<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;{<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;alert( \"Received error - \" + err.description );<br/>" +
"&nbsp;&nbsp;&nbsp;&nbsp;}<br/>" +
"&nbsp;&nbsp;&nbsp;}<br\>" + 
"&nbsp;&nbsp;&lt;/script&gt;<br\>" +
"&nbsp;&lt;/head&gt;<br\>" + 
"&nbsp;&lt;body onload=\"initService()\"&gt;<br\>" +
"&nbsp;&nbsp;&lt;a href=\"javascript:doInvoke()\"&gt;Invoke " + selectedMethod.name + " Method&lt;/a&gt;<br/>" +
"&nbsp;&lt;/body&gt;<br\>" +
"&lt;/html&gt;";
    
     document.getElementById("sourcecode").innerHTML = code; 
}

function valueToCode( objName, val )
{
	var code = "";
	
	if( isObject( val ) )
	{
		code += "&nbsp;&nbsp;&nbsp;&nbsp;" + objName + " = new " + val.__woproto__ + "();<br/>";
		
		for( var i in val )
		{
			if( i == "__woproto__" ) continue;
			code += valueToCode( objName + "." + i, val[ i ] );
		}
	}
	else if( isArray( val ) )
	{
		code += "&nbsp;&nbsp;&nbsp;&nbsp;" + objName + " = new Array();<br/>";
		
		for( var i = 0; i < val.length; i++ )
			code += valueToCode( objName + "[" + i + "]", val[ i ] );	
	}
	else
	{
		code += "&nbsp;&nbsp;&nbsp;&nbsp;" + objName + " = ";
		
		var field = document.getElementById( val );
		
		if( field.className == "datepicker" )
			code += "new Date( Date.parse( \"" + field.value + "\" ) );";
		else 
			code += (field.type == 'checkbox') ? field.checked : "'" + field.value + "'";	 

		code += ";<br/>";
	}
	
	return code;
}


function initDisplay()
{
 document.getElementById( "classname" ).innerHTML = className;
 var signatures = readSignatures(methodInfo);
 var select = document.getElementById('availableSignatures');
 select.options[select.options.length] = new Option('Select a method', '', true);

 for(var i = 0; i < signatures.length; i++)
 {
   var signature = signatures[i];
   select.options[select.options.length] = new Option(signature, '');
 }
}

function methodSelected()
{
  counter = 0;
  nameCounter=0;
  var selectedSignature = "";
  var selectedSignatureIndex = 0;

  var select = document.getElementById('availableSignatures');
  
  for (var i = 0; i < select.options.length; i++ )
  {
    if( select.options[i].selected )
    {
      selectedSignature = select.options[i].text;
      selectedSignatureIndex = i-1;
    }
  }

  document.getElementById('methodInfo').html = selectedSignature;
  var selectedMethod = methodInfo[selectedSignatureIndex];
  buildArgumentsForm(selectedMethod);
  generateSource();
}

function buildArgumentsForm(selectedMethod)
{
  counter = 0
  var result = "";
  document.getElementById('resultWrapper').style.display="none";
  document.getElementById('resultTable').innerHTML = '';
  //model = createArgumentModel(selectedMethod['args']);
  
  // this is a map between IDs and objects to be added through AddItem links
  model.addItemMap = new Object();
  result = modelToHTML(selectedMethod);
  document.getElementById('argsWrapper').innerHTML = result;
  calendar.initAllInputs();
  document.getElementById('requestedParametersWrapper').style.display="block";
}

function onInvoke()
{
  var result = invoke();
  document.getElementById('resultTable').innerHTML = processResponse(result);
  document.getElementById('resultWrapper').style.display="block";
}	

function getElementsByClassName(className) {
	var hasClassName = new RegExp("(?:^|\\s)" + className + "(?:$|\\s)");
	var allElements = document.getElementsByTagName("*");
	var results = [];

	var element;
	for ( var i = 0; (element = allElements[i]) != null; i++) {
		var elementClass = element.className;
		if (elementClass && elementClass.indexOf(className) != -1
				&& hasClassName.test(elementClass))
			results.push(element);
	}

	return results;
}

function readSignatures(methodInfo) 
{
	var result = new Array();

	for ( var i = 0; i < methodInfo.length; i++) 
	{
		var method = methodInfo[i];
		var methodSignature = "";

		methodSignature += method['name'];
		methodSignature += "( ";
		methodSignature += readArgsAsString(method['args']);
		methodSignature += " )";
		result[i] = methodSignature;
	}

	return result;
}

function readArgsAsString(arguments) 
{
	var result = "";

	for ( var k = 0; k < arguments.length; k++) 
	{
		if( isFunction( arguments[k] ) )
		{
			result = result + arguments[k].name + " arg" + k;
		}
		else if (isObject(arguments[k])) 
		{
			if( arguments[k].hasOwnProperty("__woproto__"))
				result = result + " " + arguments[k].__woproto__ + " arg" + k;
			else
				result = result + " Object arg" + k;
		} 
		else if (isArray(arguments[k])) 
		{
			var arrayType = getArrayType(arguments[k]);
			result = result + " " + arrayType + " arg" + k;
		}
		else 
		{
			result = result + toUpperCase(arguments[k]) + " arg" + k;
		}

		if (k < (arguments.length - 1) && arguments.length != 1) 
			result += ", ";
	}

	return result;
}

function getArrayType(arg) 
{
	if (arg.length == 0) 
	{
		// should I exclude an argument in this case, or create a default type?
	}
	else
	{
		var arrayTypeObj = arg[0];

		if( isFunction( arrayTypeObj ) )
			return arrayTypeObj.name + "[]"; 
		else if (isObject(arrayTypeObj)) 
			return (arrayTypeObj.hasOwnProperty( "__woproto__" ) ? arrayTypeObj.__woproto__ : "Object") + "[]";
		else if (isArray(arrayTypeObj)) 
			return getArrayType(arrayTypeObj);
		else 
			return toUpperCase( arrayTypeObj ) + "[]";
	}
}

function toUpperCase(obj) 
{
    if (obj.name)
    	return obj.name;
 
	return obj.replace(/^./, obj.match(/^./)[0].toUpperCase());
}

function isArray(argument) 
{
	if( argument == undefined )
  		return false;
  
	return argument.constructor.toString().indexOf("Array") != -1;
}

function isObject(argument) 
{
	if( argument == undefined )
  		return false;
  
	return argument.constructor.toString().indexOf("Object") != -1;
}

function isFunction( argument )
{
	return typeof argument == 'function';
}

function objectToString(o) 
{
	var parse = function(_o) 
	{
		var a = [], t;
		for ( var p in _o) 
		{
			if( p == "__woproto__" )
				continue;
				
			if (_o.hasOwnProperty(p)) 
			{
				t = _o[p];
				
				if( isObject( t ) )
					a[a.length] = p + ":{ " + arguments.callee(t).join(", ") + "}";
				else if( isArray( t ) )
					a[a.length] = p + ":" + arrayToString( t );
				else 
				{
					if (typeof t == "string") 
						a[a.length] = [ p + ": " + t.toString() ];
					else
						a[a.length] = [ p + ": " + t.toString() ];
				}
			}
		}
		return a;
	};

	return "{" + parse(o).join(", ") + "}";
}

function arrayToString(o) 
{
	var result = "[";

	for ( var i = 0; i < o.length; i++) 
	{
		var element = "";

		if (isObject(o[i])) 
			element = objectToString(o[i]);
		else if (isArray(o[i])) 
			element = arrayToString(o[i]);
		else 
			element = o[i];

		if (o.length != 1) 
			if (o.length != (i + 1)) 
				element += ", ";

		result += element;
	}

	result += "]";

	return result;
}

function modelToHTML(model) 
{
	var result = "<table border='1' class='dataTable'><thead><tr><th>Argument</th><th>Type</th><th>Value</th></tr></thead>";

	model.argModel = new Object();
	
	for ( var i = 0; i < model.args.length; i++) 
		result += entryToHtml( "arg" + i, model.args[i], 0, model.argModel );

	result += '</table>';
	return result;
}

function entryToHtml( objName, entry, entryDepth, entryParent ) 
{
	var result = '';
	
	if( isFunction( entry ) )
		return objectEntryToHtml( objName, entry.prototype, entryDepth, entryParent );
	else if( isObject( entry ) )
		return objectEntryToHtml( objName, entry, entryDepth, entryParent );
	else if( isArray( entry ) )
		return arrayEntryToHtml( objName, entry, entryDepth, entryParent );
	else
		return primitiveEntryToHtml( objName, entry, entryDepth, entryParent );

	return result;
}

function objectEntryToHtml( objName, entry, entryDepth, entryParent) 
{
    if( getPropertyCount( entry ) == 0 )
       return primitiveEntryToHtml( objName, "string", entryDepth, entryParent );
       
    var modelObj = new Object();
       
	var result = "<tr><td style='padding-left:" + ((entryDepth + 1) * 10) + "px'>"
			+ (isArray( entryParent ) ? "[" +objName+ "]" : objName) + "</td><td>Object</td><td style='background:#cecece'></td></tr>";

	if( propertyCounter( entry ) == 1 )
	{
		var className = entry.__woproto__;
		entry = eval( entry.__woproto__ ).prototype;
		entry.__woproto__ = className;
	}
	
	for ( var i in entry )
	{
		if( i == "__woproto__" )
		{
			modelObj.__woproto__ = entry[ i ];
			continue;
		}
		
		result += entryToHtml( i, entry[ i ], entryDepth + 1, modelObj );
	}
	
	if( isArray( entryParent[ objName ] ) )
		entryParent[ objName ].push( modelObj );
	else
		entryParent[ objName ] = modelObj;

	return result;
}

function arrayEntryToHtml( objName, entry, entryDepth, entryParent ) 
{
	var result = "<tr><td style='padding-left:" + ((entryDepth + 1) * 10) + "px'>";

	result += objName;
	result += "</td><td>";
	result += "Array";
	result += "</td><td>";

	//var addLink = "<a href='javascript:void(0)' onClick='addArrayObject(" + entry.rootPosition + ", " + entryDepth + ", \"" + entry.name + "\", this);' title=''>Add item</a>";
	var addLink = "<a href='javascript:void(0)' onClick='addArrayObject(" + arrayIDCounter + "," + (entryDepth + 1) +");' title=''>Add item</a>";

	result += addLink;
	result += "</td></tr><tr id='addItem" + arrayIDCounter  + "' style='display:none'></tr>";

	var modelObj = [];
	entryParent[ objName ] = modelObj;
	model.addItemMap[ arrayIDCounter ] = {entry:entry, model:modelObj};
	arrayIDCounter++;
	
	return result;
}

function primitiveEntryToHtml( objName, entry, entryDepth, entryParent ) 
{
	if( isArray( entryParent[ objName ] ) )
		entryParent[ objName ].push( counter );
	else
		entryParent[ objName ] = counter;
	
	if( entry == undefined )
		entry = "string";
	 
	var result = "<tr><td style='padding-left:" + ((entryDepth + 1) * 10) + "px'>";
	result += isArray( entryParent ) ? ("[" + objName + "]") : objName;
	result += "</td><td>";
	
	if( entry instanceof Date || entry == "date" )
		result += "Date";
	else if( typeof( entry ) == "number" || entry == "number" )
		result += "Number";		
	else if( typeof( entry ) == "string" )
		result += "String";
	else if( entry == null )
		result += "Object";
	else
		result += entry;

	result += "</td><td>";
	
	var inputElement;
	
	if (entry == 'boolean') 
		inputElement = "<input type='checkbox'  id='" + counter + "' value='bool'>";
	else if (entry instanceof Date || entry == 'date' ) 
		inputElement = "<input type='text' class='datepicker' id='" + counter + "' />";
	else 
		inputElement = "<input type='text' onkeyup='generateSource()' id='" + counter + "' />";
	

	counter++;
	result += inputElement;
	result += "</td></tr>";
	return result;
}

function getPropertyCount( obj )
{
	var keysCount = 0;
	for (k in obj) if (obj.hasOwnProperty(k)) keysCount++;
	
	return keysCount;
}

function addArrayObject( arrayID, entryDepth )
{
	var arrayObjModel = model.addItemMap[ arrayID ]; 
	var rendering = entryToHtml( getPropertyCount( arrayObjModel.model ), arrayObjModel.entry[0], entryDepth, arrayObjModel.model );
	var placeHolderRow = document.getElementById( "addItem" + arrayID );
	var tempTable = document.createElement( "table" );
	tempTable.innerHTML = rendering;
	
	var rows;
	
	if( tempTable.firstChild.nodeName.toUpperCase() == "TBODY" )
	  rows = tempTable.firstChild.childNodes;
	else
	  rows = tempTable.childNodes;
	
	while( rows.length > 0 )
		placeHolderRow.parentNode.insertBefore( rows[ 0 ], placeHolderRow );
		
  	calendar.initAllInputs();		
}

function invoke() 
{
	responseRowCounter = 0;
	model.idToChildIDs = {};
    var methodSelector = document.getElementById('availableSignatures'); 
    var selectedMethod = methodInfo[ methodSelector.selectedIndex - 1 ];
  
	var parameters = "";

	for ( var i = 0; i < selectedMethod.args.length; i++) 
	{
		var arg = argFromModel( selectedMethod.argModel )[ "arg" + i ];
		
		if( isObject( arg ) ) 
			parameters += objectToString( arg );
		else if( isArray( arg ) )
			parameters += arrayToString( arg );
		else
			parameters += arg;

		if ( i != selectedMethod.args.length - 1)
			parameters += ", ";
	}

	var methodCall = "service." + selectedMethod.name + "(" + parameters + ");";
	
	var beforeCall = new Date().getTime();
	var result;
	try
	{
	 result = eval(methodCall);
	}
	catch(error)
	{
		alert( "Server reported an error: " + error.description );
	}
	var duration = new Date().getTime() - beforeCall;
	renderInvocationHistory( duration, selectedMethod.name );
	return result;
}

function renderInvocationHistory( duration, fnName )
{
	var currentTime = new Date()
	var hours = currentTime.getHours()
	var minutes = currentTime.getMinutes()
	var seconds = currentTime.getSeconds();
	
	if (minutes < 10)
		minutes = "0" + minutes;
	if (seconds < 10)
		seconds = "0" + seconds;

	var invhistory = document.getElementById( "invhistory" );
	
	invhistory.innerHTML += "<div class='historyline'><span class='ts'>" + hours + ":" + minutes + ":" + seconds + "</span><span class='method'>" + fnName + "</span><span class='duration'>" + duration + "ms</span></div>";
}

function clearInvHistory()
{
	var invhistory = document.getElementById( "invhistory" );	
	invhistory.innerHTML = "";
}

function argFromModel( formDataModel )
{
	var isArr = isArray( formDataModel );
	var obj = isArr ? new Array() : new Object();
	
	for( var i in formDataModel )
	{
		if( i == "__woproto__" )
			continue;
				
		var newObj;
		
		if( isObject( formDataModel[ i ] ) || isArray( formDataModel[ i ] ) )
			newObj = argFromModel( formDataModel[ i ] )
		else
			newObj = getPrimitive( formDataModel[ i ] );
		
		if( isArr )
			obj.push( newObj );
		else
			obj[ i ] = newObj;			
	}
	
	return obj;
}

function getPrimitive( id )
{
	var field = document.getElementById( id );
	
	if( field.className == "datepicker" )
		return Date.parse( field.value );
	else 
		return (field.type == 'checkbox') ? field.checked : "'" + field.value + "'";
}

function processResponse(obj) 
{
	var result = "<table id='resultTable' class='dataTable' border='1'><thead><tr><th>Name</th><th>Type</th><th>Value</th></tr></thead>";
	result += parseResponse(obj, null, 5, true, null);
	result += "</table>";
	return result;
}

function parseResponse(obj, name, padding, displayable, arrayOfIDs) 
{
	var result = '';

	if (isObject(obj))
		result += parseObject(obj, name, padding, displayable, arrayOfIDs);
	else if (isArray(obj))
		result += parseArray(obj,  name, padding, displayable, arrayOfIDs);
	else
		result += parsePrimitive(obj, name, padding, displayable, arrayOfIDs);

	return result;
}

function parseObject(obj, name, padding, displayable, arrayOfIDs) 
{
    if( obj instanceof RecordSet )
    {
      obj = obj.getInitialPage();
      return parseResponse( obj, name, padding, displayable );
    }
      
	var result = '';
	
	if( arrayOfIDs != null )
		arrayOfIDs[ arrayOfIDs.length ] = responseRowCounter;	
	
	var displayStyle = (!displayable) ? " style='display:none' " : "";
	result += "<tr id='R" + responseRowCounter++ + "'" + displayStyle + "><td style='padding-left:" + padding + "px '>";

	if (name == null) 
		result += "Object";
	else 
		result += name;

	var objDetailsResult = "";
	var rowIDs = [];
	model.idToChildIDs[ responseRowCounter - 1 ] = rowIDs; 
	
	for ( var property in obj) 
	{
		if( property == "__woproto__" )
			continue;
			
		objDetailsResult += parseResponse(obj[property], property, (10 + padding), displayable, rowIDs);
	}

	var control = "<a href='javascript:void(0);' style='text-decoration: none;' onclick='manageResultClickHandler(" + arrayToString(rowIDs) + ");'> + </a> ";
	result += "</td><td>" + control + "Object</td><td style='background:#ccc'></td></tr>";
	result += objDetailsResult;

	return result;
}

function propertyCounter(myobj) 
{
	var count = 0;
	for (k in myobj)
		if (myobj.hasOwnProperty(k))
			count++;

	return count;
}

function parseArray(obj, name, padding, displayable, arrayOfIDs) 
{
	if( arrayOfIDs != null )
		arrayOfIDs[ arrayOfIDs.length ] = responseRowCounter;
		
	var displayStyle = (!displayable) ? " style='display:none' " : "";
	var result = "<tr id='R" + responseRowCounter++ + "'" + displayStyle + "><td style='padding-left:" + padding + "px '>" + (name == null ? "Result" : name) + "</td>";

	var objDetailsResult = "";
	var arrayElementRows = [];
	model.idToChildIDs[ responseRowCounter - 1 ] = arrayElementRows; 
	
	for ( var i = 0; i < obj.length; i++) 
		objDetailsResult += parseResponse(obj[i], '[' + i + ']', padding + 10, displayable ? ! (isObject(obj[i]) || isArray(obj[i])) : false, arrayElementRows );

	var control = "<a href='javascript:void(0);' style='text-decoration: none;' onclick='manageResultClickHandler(" + arrayToString(arrayElementRows) + ");'> + </a> ";
	result += "<td>" + control + "Array</td><td style='background:#ccc'></td></tr>";
	result += objDetailsResult;

	return result;
}

function parsePrimitive(obj, name, padding, displayable, arrayOfIDs) 
{
	if( arrayOfIDs != null )
		arrayOfIDs[ arrayOfIDs.length ] = responseRowCounter;
		
	var displayStyle = (!displayable) ? " style='display:none' " : "";
	var result = "<tr id='R" + responseRowCounter++ + "'" + displayStyle + "><td style='padding-left:" + padding + "px '>";
	result += (name == null) ? "Result" : name;
	result += "</td><td>";
	result += typeof obj;
	result += "</td><td>";
	result += obj;
	result += "</td></tr>";
	return result;
}

function manageResultClickHandler( rowIDs, forceHiding ) 
{
	for( var i = 0; i < rowIDs.length; i++ )
	{
		var row = document.getElementById( "R" + rowIDs[ i ] );
		row.style.display = (forceHiding || row.style.display == '') ?  'none' : '';
		
		if( row.style.display == 'none' )
		{
			var IDsToHide = model.idToChildIDs[ rowIDs[ i ] ];	
			
			if( IDsToHide )
				manageResultClickHandler( IDsToHide, true );		
		}
	}
}


/*
 * 
 */

calendar = {
	month_names: ["January","February","March","April","May","June","July","Augest","September","October","November","December"],
	weekdays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
	month_days: [31,28,31,30,31,30,31,31,30,31,30,31],
	// Get today's date - year, month, day and date
	today : new Date(),
	opt : {},
	data: [],

	// Functions
	// / Used to create HTML in a optimized way.
	wrt:function(txt) {
		this.data.push(txt);
	},
	
	getStyle: function(ele, property){
		if (ele.currentStyle) {
			var alt_property_name = property.replace(/\-(\w)/g,function(m,c){return c.toUpperCase();});// background-color
																										// becomes
																										// backgroundColor
			var value = ele.currentStyle[property]||ele.currentStyle[alt_property_name];
		
		} else if (window.getComputedStyle) {
			property = property.replace(/([A-Z])/g,"-$1").toLowerCase();// backgroundColor
																		// becomes
																		// background-color

			var value = document.defaultView.getComputedStyle(ele,null).getPropertyValue(property);
		}
		
		// Some properties are special cases
		if(property == "opacity" && ele.filter) value = (parseFloat( ele.filter.match(/opacity\=([^)]*)/)[1] ) / 100);
		else if(property == "width" && isNaN(value)) value = ele.clientWidth || ele.offsetWidth;
		else if(property == "height" && isNaN(value)) value = ele.clientHeight || ele.offsetHeight;
		return value;
	},
	getPosition:function(ele) {
		var x = 0;
		var y = 0;
		while (ele) {
			x += ele.offsetLeft;
			y += ele.offsetTop;
			ele = ele.offsetParent;
		}
		if (navigator.userAgent.indexOf("Mac") != -1 && typeof document.body.leftMargin != "undefined") {
			x += document.body.leftMargin;
			offsetTop += document.body.topMargin;
		}
	
		var xy = new Array(x,y);
		return xy;
	},
	// / Called when the user clicks on a date in the calendar.
	selectDate:function(year,month,day) {
		var ths = _calendar_active_instance;
		document.getElementById(ths.opt["input"]).value =month + "/" + day + "/" +year;
		generateSource();
		ths.hideCalendar();
	},
	// / Creates a calendar with the date given in the argument as the selected
	// date.
	makeCalendar:function(year, month, day) {
		year = parseInt(year);
		month= parseInt(month);
		day	 = parseInt(day);
		
		// Display the table
		var next_month = month+1;
		var next_month_year = year;
		if(next_month>=12) {
			next_month = 0;
			next_month_year++;
		}
		
		var previous_month = month-1;
		var previous_month_year = year;
		if(previous_month< 0) {
			previous_month = 11;
			previous_month_year--;
		}
		
		this.wrt("<table>");
		this.wrt("<tr><th><a href='javascript:calendar.makeCalendar("+(previous_month_year)+","+(previous_month)+");' title='"+this.month_names[previous_month]+" "+(previous_month_year)+"'>&lt;</a></th>");
		this.wrt("<th colspan='5' class='calendar-title'><select name='calendar-month' class='calendar-month' onChange='calendar.makeCalendar("+year+",this.value);'>");
		for(var i in this.month_names) {
			this.wrt("<option value='"+i+"'");
			if(i == month) this.wrt(" selected='selected'");
			this.wrt(">"+this.month_names[i]+"</option>");
		}
		this.wrt("</select>");
		this.wrt("<select name='calendar-year' class='calendar-year' onChange='calendar.makeCalendar(this.value, "+month+");'>");
		var current_year = this.today.getYear();
		if(current_year < 1900) current_year += 1900;
		
		for(var i=current_year-70; i<current_year+10; i++) {
			this.wrt("<option value='"+i+"'");
			if(i == year) this.wrt(" selected='selected'");
			this.wrt(">"+i+"</option>");
		}
		this.wrt("</select></th>");
		this.wrt("<th><a href='javascript:calendar.makeCalendar("+(next_month_year)+","+(next_month)+");' title='"+this.month_names[next_month]+" "+(next_month_year)+"'>&gt;</a></th></tr>");
		this.wrt("<tr class='header'>");
		for(var weekday=0; weekday<7; weekday++) this.wrt("<td>"+this.weekdays[weekday]+"</td>");
		this.wrt("</tr>");
		
		// Get the first day of this month
		var first_day = new Date(year,month,1);
		var start_day = first_day.getDay();
		
		var d = 1;
		var flag = 0;
		
		// Leap year support
		if(year % 4 == 0) this.month_days[1] = 29;
		else this.month_days[1] = 28;
		
		var days_in_this_month = this.month_days[month];

		// Create the calender
		for(var i=0;i<=5;i++) {
			if(w >= days_in_this_month) break;
			this.wrt("<tr>");
			for(var j=0;j<7;j++) {
				if(d > days_in_this_month) flag=0; // If the days has
													// overshooted the number of
													// days in this month, stop
													// writing
				else if(j >= start_day && !flag) flag=1;// If the first day of
														// this month has come,
														// start the date
														// writing

				if(flag) {
					var w = d, mon = month+1;
					if(w < 10)	w	= "0" + w;
					if(mon < 10)mon = "0" + mon;

					// Is it today?
					var class_name = '';
					var yea = this.today.getYear();
					if(yea < 1900) yea += 1900;

					if(yea == year && this.today.getMonth() == month && this.today.getDate() == d) class_name = " today";
					if(day == d) class_name += " selected";
					
					class_name += " " + this.weekdays[j].toLowerCase();

					this.wrt("<td class='days"+class_name+"'><a href='javascript:calendar.selectDate(\""+year+"\",\""+mon+"\",\""+w+"\")'>"+w+"</a></td>");
					d++;
				} else {
					this.wrt("<td class='days'>&nbsp;</td>");
				}
			}
			this.wrt("</tr>");
		}
		this.wrt("</table>");
		this.wrt("<input type='button' value='Cancel' class='calendar-cancel' onclick='calendar.hideCalendar();' />");

		document.getElementById(this.opt['calendar']).innerHTML = this.data.join("");
		this.data = [];
	},
	
	// / Display the calendar - if a date exists in the input box, that will be
	// selected in the calendar.
	showCalendar: function() {
		var input = document.getElementById(this.opt['input']);
		
		// Position the div in the correct location...
		var div = document.getElementById(this.opt['calendar']);
		var xy = this.getPosition(input);
		var width = parseInt(this.getStyle(input,'width'));
		div.style.left=(xy[0]+width+10)+"px";
		div.style.top=xy[1]+"px";

		// Show the calendar with the date in the input as the selected date
		var existing_date = new Date();
		var date_in_input = input.value;
		if(date_in_input) {
			var selected_date = false;
			var date_parts = date_in_input.split("-");
			if(date_parts.length == 3) {
				date_parts[1]--; // Month starts with 0
				selected_date = new Date(date_parts[0], date_parts[1], date_parts[2]);
			}
			if(selected_date && !isNaN(selected_date.getYear())) { // Valid
																	// date.
				existing_date = selected_date;
			}
		}
		
		var the_year = existing_date.getYear();
		if(the_year < 1900) the_year += 1900;
		this.makeCalendar(the_year, existing_date.getMonth(), existing_date.getDate());
		document.getElementById(this.opt['calendar']).style.display = "block";
		_calendar_active_instance = this;
	},
	
	// / Hides the currently show calendar.
	hideCalendar: function(instance) {
		var active_calendar_id = "";
		if(instance) active_calendar_id = instance.opt['calendar'];
		else active_calendar_id = _calendar_active_instance.opt['calendar'];
		
		if(active_calendar_id) document.getElementById(active_calendar_id).style.display = "none";
		_calendar_active_instance = {};
	},
	
	initAllInputs: function()
	{
		var datepickerInputs = getElementsByClassName('datepicker');
		
		for(var i = 0; i < datepickerInputs.length; i++)
		{
			calendar.set(datepickerInputs[i].id);
		}
	},
	
	// / Setup a text input box to be a calendar box.
	set: function(input_id) {
		
		
		
		var input = document.getElementById(input_id);
		if(!input) return; // If the input field is not there, exit.
		
		if(!this.opt['calendar']) this.init();
		
		var ths = this;
		input.onclick=function(){
			ths.opt['input'] = this.id;
			ths.showCalendar();
		};
	},
	
	// / Will be called once when the first input is set.
	init: function() {
		if(!this.opt['calendar'] || !document.getElementById(this.opt['calendar'])) {
			var div = document.createElement('div');
			if(!this.opt['calendar']) this.opt['calendar'] = 'calender_div_'+ Math.round(Math.random() * 100);

			div.setAttribute('id',this.opt['calendar']);
			div.className="calendar-box";

			document.getElementsByTagName("body")[0].insertBefore(div,document.getElementsByTagName("body")[0].firstChild);
		}
	}
	
	
}
var TINY={};function T$(i){return document.getElementById(i)}function T$$(e,p){return p.getElementsByTagName(e)}TINY.accordion=function(){function slider(n){this.n=n;this.a=[]}slider.prototype.init=function(t,e,m,o,k){var a=T$(t),i=s=0,n=a.childNodes,l=n.length;this.s=k||0;this.m=m||0;for(i;i<l;i++){var v=n[i];if(v.nodeType!=3){this.a[s]={};this.a[s].h=h=T$$(e,v)[0];this.a[s].c=c=T$$('div',v)[0];h.onclick=new Function(this.n+'.pr(0,'+s+')');if(o==s){h.className=this.s;c.style.height='auto';c.d=1}else{c.style.height=0;c.d=-1}s++}}this.l=s};slider.prototype.pr=function(f,d){for(var i=0;i<this.l;i++){var h=this.a[i].h,c=this.a[i].c,k=c.style.height;k=k=='auto'?1:parseInt(k);clearInterval(c.t);if((k!=1&&c.d==-1)&&(f==1||i==d)){c.style.height='';c.m=c.offsetHeight;c.style.height=k+'px';c.d=1;h.className=this.s;su(c,1)}else if(k>0&&(f==-1||this.m||i==d)){c.d=-1;h.className='';su(c,-1)}}};function su(c){c.t=setInterval(function(){sl(c)},20)};function sl(c){var h=c.offsetHeight,d=c.d==1?c.m-h:h;c.style.height=h+(Math.ceil(d/5)*c.d)+'px';c.style.opacity=h/c.m;c.style.filter='alpha(opacity='+h*100/c.m+')';if((c.d==1&&h>=c.m)||(c.d!=1&&h==1)){if(c.d==1){c.style.height='auto'}clearInterval(c.t)}};return{slider:slider}}();		


