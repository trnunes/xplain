/**
 * @author samuraraujo
 */
var loading_text="Loading ..."
//Execute an AJAX request , updating the container with the response text.
function ajax_update_callback(id, _uri, callbackfunction){
    $(id).innerHTML = 'Loading....'
    new Ajax.Request((_uri), {
        method: 'post',
        onComplete: function(transport){
            Element.replace(id, transport.responseText);
            init_all();
            eval(callbackfunction);
        }
    });
}

function ajax_update(id, _uri){
	$.ajax({
		type: 'POST',
		url: _uri,
		data_type: 'script',
		success: function(data, status, jqrequest) {			
			$('#' + id).replaceWith(data);
			init_all();
		}
	});
}

//Execute an AJAX request , updating the container with the response text.
function ajax_insert(element, _uri, callbackfunction){
    new Ajax.Request((_uri), {
        method: 'post',
        onComplete: function(transport){
            element.insert(transport.responseText);
            init_all();
            eval(callbackfunction);
        }
    });
}

//Execute a ajax request.
function ajax_request(uri){

    $('#loadwindow').show();
	console.log("REQUEST EXECUTED");
	$.ajax({
		type: 'GET',
		url: uri,
		success: function(data, status, jqrequest){
			$('#loadingtext').innerHTML = loading_text;
            $('#loadwindow').hide();

		}
	});
}

//TODO: consertar facetas
//Execute a ajax request.
function ajax_request_forfacet(uri, item){
    $('#loadwindow').show();
    $.ajax({
        type: 'get',
		url: uri,
        success: function(data, status, jqrequest){
			$('#loadingtext').innerHTML = loading_text;
            $('#loadwindow').hide();
            
            ui_add_window(data);
            $('facetgroup').append(item);
        }
    });
}

//Execute a AJAX request for remove something in the server
//This methods do not update the interface.
function ajax_remove(_uri){
	$.ajax({
		type: 'GET',
		url: _uri,
		error: function(data, status, jqrequest){
			alert(data);
		}
	});
}

//execute a AJAX request, creating a new container with the content return by the request.
function ajax_create(_uri){
    // $('#loadwindow').show();
	$.ajax({
		type: "GET",
		url: executeuri + _uri,
		data_type: "script",
		success: function(data, status, jqrequest) {
			
		}
	});    
}	
function ajax_paginate(set_id, page){
	// $('#loadwindow').show();
	$.ajax({
		type: "GET",
		url: "/session/nextpage?set="+set_id+ "&page=" + page,
		data_type: "script",
		success: function(data, status, jqrequest) {

		}
	});    

}

function ajax_renderdomain(set_id, page){
	$.ajax({
		type: "GET",
		url: "/session/renderdomain?set="+set_id+ "&page=" + page,
		data_type: "script",
		success: function(data, status, jqrequest) {

		}
	});   
}
