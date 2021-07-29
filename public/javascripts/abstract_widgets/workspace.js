XPLAIN.widgets = XPLAIN.widgets || {}
XPLAIN.states = XPLAIN.states || {}

XPLAIN.alertErrors = function(errors) {
	if (errors) {
		errorStr = ""
		errors.forEach(function(err){ errorStr += err + "\n"});
		return alert(errorStr);
	}
}

XPLAIN.widgets.DefaultWorkspaceWidget = function(workspaceState){
	
	
	XPLAIN.widgets.Widget.call(this, null, workspaceState);
	this.params_hash = new Hashtable();
	
	this.save_url = "/session/save_session.json"
	this.execute_url = "/session/execute.json";
	
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype = Object.create(XPLAIN.widgets.Widget.prototype)

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.build = function(){
	
	XPLAIN.widgets.Widget.prototype.build.call(this);
	this.registerBehavior();
}
	
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerBehavior = function(){
	var currentXhr;
	currentXhr = null;

	$(document).on('ajax:send', function(_event, xhr) {
	  if (currentXhr) {
		currentXhr.abort();
		debugger;
	  }
	  currentXhr = xhr;
	  return true;
	});
	$(document).on('ajax:complete', function(_event, _xhr, _status) {
	  currentXhr = null;
	});

	$(".help_btn").unbind().click(function(){
		if ($('#' + $(this).attr("operation") + "_help").is(':empty')){
			XPLAIN.AjaxHelper.get("/session/help?operation=" + $(this).attr("operation"));
		}else{
			$('#' + $(this).attr("operation") + "_help").empty();
	
		}

	});

	this.registerLandmarkHandlers();
	this.registerExplorationBehavior();
}
	
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.addWidgetToView = function(widget){
	debugger;
	
	if ($('#exploration_area').find('.set').length > 0) {
	
		$(widget.html).insertBefore($('#exploration_area').find('.set').first());
				
	} else {
		debugger
		widget.html.insertAfter($('#graph_view'));
	}
	
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.onAddSet = function(eventJson){
	var addedSetState = eventJson.data;
	var abstractSetWidget = new XPLAIN.widgets.SetWidget(this, addedSetState);
	
	var setWidget = XPLAIN.widgets.createView(abstractSetWidget, addedSetState.setJson);
	
	abstractSetWidget.build();
	XPLAIN.graph.addSet(addedSetState.setJson);
	this.addWidgetToView(setWidget)
	
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.onDeleteSet = function(eventJson){
	var removedSetId = eventJson.data.removedSet;
	debugger;
	$("[data-id='" + removedSetId + "']").ui_remove();
	XPLAIN.graph.removeSet(removedSetId);
}

	
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerLandmarkHandlers = function(){
	var thisWidget = this;
	$("#all_types").unbind().click(function(){
		debugger;
		var expression = "Xplain::ExecuteRuby.new(code: 'Xplain::SchemaRelation.new(id: \"has_type\", server: @server).image.sort_asc!')"
		let xplain_session = $("#session_name").data("sessionId");
		let url = "/session/execute.json?exp="+ expression + "&xplain_session=" + xplain_session;
		XPLAIN.AjaxHelper.get(url, "json", function(data){
			
			if (data.errors){
				return XPLAIN.alertErrors(data.errors)
			}
			thisWidget.state.addSetFromJson(data);
		});
	});

	$("#all_relations").unbind().click(function(){
		var expression = "Xplain::ExecuteRuby.new(code: 'Xplain::SchemaRelation.new(id: \"relations\", server: @server).image.sort_asc!').rank"
		let xplain_session = $("#session_name").data("sessionId");
let url = "/session/execute.json?exp="+ expression + "&xplain_session=" + xplain_session;
        XPLAIN.AjaxHelper.get(url, "json", function(data){
			if (data.errors){
				return XPLAIN.alertErrors(data.errors)
			}
			thisWidget.state.addSetFromJson(data);
		});
	});
    
    $('#set_endpoint_btn').click(function (e) {
        var endpoint_url = $('#input_url').val().trim();
        var named_graph_uri = $('#ngraph_uri').val().trim();
        var http_method = $("#endpoint_modal [name=http-method]:checked").val();
		var max_items_per_query = $("#endpoint_modal #max_items").val().trim();
		if (!endpoint_url){
			e.stopPropagation();
			return alert("you should provide a URL for the endpoint");
		}
        
		// mounting endpoint config url
		let session_id = $("#session_name").data("sessionId") || "	";
		let endpoint = $("#endpoint_url").text();

        var url = "/session/set_endpoint?xplain_session="+session_id+"&method="+http_method+"&items_limit=" + max_items_per_query + "&graph=" +  encodeURIComponent(endpoint_url)+ "&named_graph=" +  encodeURIComponent(named_graph_uri);

        if ($("#endpoint_modal #blazegraph_search_idx:checked").size()){
            url += "&class=BlazegraphDataServer";            
        } else {
        	url += "&class=Xplain::RDF::DataServer";
		}
		if ($("#dbpedia_lookup:checked")) {
			url += "&lookup_service=Xplain::DbpediaLookup"
		}

        
        if (endpoint_url) {
            XPLAIN.AjaxHelper.get(url, "json", function(data){
            	if (!data.error){
            		$("#endpoint_url").text(endpoint_url);
            	}
            		
            });
        } else {
        	alert("The endpoint url cannot be empty!")
        }
       
     });

     $('#set_delete').unbind().click(function(){
     	if (!$('.SELECTED.set').length) {
     		alert("Please select at least one exploration set!");
     		return;
     	}

     	for (var i = 0; i < $('.SELECTED.set').length; i++){
     		var setId = $($('.SELECTED.set')[i]).attr("data-id");
     		thisWidget.state.deleteSetState(setId);
     	}
     	
     });


}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.list_sessions = function(){
	var thisWidget = this;
	
	
	XPLAIN.AjaxHelper.get("/session/list_sessions.json", "json", function(data){
	
		$("#section_list_modal").remove();
		$("body").append(data.html);
		$("#section_list_modal").modal("show")
	});
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_session = function(name, callback){
	var thisWidget = this;
	debugger;
	if (!name){
		name = $("input:radio[name=radio_session]:checked").parent().text();
	}

	XPLAIN.AjaxHelper.get("/session/load_session.json?name=" + name, "json", function(data){
		thisWidget.load_session_data(data);
		if (callback){
			callback(data);
		}
	});
}
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_session_data = function(data){
	var thisWidget = this;
	$('.set').remove();
	XPLAIN.graph.clear();
	data.sets.forEach(function(setData){
		debugger;
		thisWidget.state.addSetFromJson(setData);
	});
	$("#session_name").text(data.name);
	$("#session_name").data("sessionId", data.id);
	debugger;
	$("#endpoint_url").text(data.server);
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_session_by_id = function(id){
    var thisWidget = this;
    debugger;
    
    XPLAIN.AjaxHelper.get("/session/load_session.json/" + id, "json", function(data){
		thisWidget.load_session_data(data);
    });
}
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_last_active_session = function(){
	var thisWidget = this;
    XPLAIN.AjaxHelper.get("/session/load_last_active_session.json", "json", function(data){
        debugger;
        $('.set').find("._remove").click()
        data.sets.forEach(function(setData){
            thisWidget.state.addSetFromJson(setData);
        });
        
        $("#session_name").text(data.name);
        
    });

}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.close_session = function(callback){
	var thisWidget = this;
	let xplain_session = $("#session_name").data("sessionId");
	let close_url = "session/close?xplain_session=" + xplain_session;
    XPLAIN.AjaxHelper.get(close_url, "json", function(data){
        
        $('.set').find("._remove").click()
        
		$("#session_name").text("Unnamed");

		if (callback){
			callback(data);
		}
        
    });

}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.reload_current_session = function(){
	var thisWidget = this;
	this.save_session(function(){
		debugger
		var session_name = $("#session_name").text();
		if (!session_name || session_name === "Unnamed"){
			return alert("You must save the current session with a valid name before setting a visualization profile.");
		}
		
		thisWidget.close_session(function(){
			console.log("Reloading session: ", session_name);
			thisWidget.load_session(session_name)
		});

	});
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.save_session_as = function(callback){
	var thisWidget = this;
	debugger;
	var name = prompt("Save session: please enter the session name", "").trim();
	if (!name){
		alert("The session name cannot be empty!");
		return
	}
	$("#session_name").text("Saving session...");
	
	param_str = "&name=" + name;
    let xplain_session = $("#session_name").data("sessionId");
	XPLAIN.AjaxHelper.get(this.save_url + "?xplain_session=" + xplain_session  + param_str, "json", function(data){
		debugger;
		alert("Session has been saved!");
		$("#session_name").text(name.trim());
		if (callback){
			callback(data);
		}
	});
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.save_session = function(callback){

	var name = $("#session_name").text().trim();
	if (name.indexOf("Unnamed") >= 0 ) {
		return this.save_session_as(callback);
	}
    let xplain_session = $("#session_name").data("sessionId");
	XPLAIN.AjaxHelper.get(this.save_url + "?xplain_session=" + xplain_session, "json", function(data){
		debugger
		if (data.errors){
			return XPLAIN.alertErrors(data.errors)
		}

		alert(data.success);
		if (callback){
			callback(data);
		}
		
	});

}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.new_session = function(){
    
    XPLAIN.AjaxHelper.get("/session/new.js", "js");

}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.create_session = function(){
	var thisWidget = this;
	debugger;
	var session_name = prompt("Please inform the name of the new session", "");
	session_name = session_name.trim();
	if (!session_name){
		alert("The session name cannot be empty!");
		return;
	}
	
	XPLAIN.AjaxHelper.get("/session/create.json?name=" + session_name, "json", function(data){
		$('.set').find("._remove").click();
		debugger;
		$("#session_name").text(session_name);
	});
	
}
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.ajax_derref = function(){
	var thisWidget= this;
	var inputValues = $("#seachbykeyword").val().trim();
	

	if (inputValues === '') {
		$("#seachbykeyword").fadeOut(50).promise().done(function () {
	        $(this).toggleClass("blink-class").fadeIn(50);
	    });

		alert("Please, type the URI to derreferentiate!");
		return this;
	} else {

		var expression =  "Xplain::ExecuteRuby.new(code: 'Xplain::ResultSet.new(nodes: [Xplain::Entity.new(\""+inputValues+"\")])')";
		let xplain_session = $("#session_name").data("sessionId");
		let url = "/session/execute.json?exp="+ expression + "&xplain_session=" + xplain_session;

		XPLAIN.AjaxHelper.get(url, "json", function(data){
			if (data.errors){
				return XPLAIN.alertErrors(data.errors)
			}
			thisWidget.state.addSetFromJson(data);
		});
	}
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.ajax_keyword_search = function(){
	var inputValues = $("#seachbykeyword").val();
	var thisWidget= this;

	if (inputValues === '') {
		$("#seachbykeyword").fadeOut(50).promise().done(function () {
	        $(this).toggleClass("blink-class").fadeIn(50);
	    });

		alert("Please, type one or more keywords!");
		return this;
	}
	let endpoint = $('#endpoint_url').text()
	let session_id = $("#session_name").data("sessionId") || "	";
	
	var expression = `Xplain::KeywordSearch.new(keyword_phrase: "${inputValues}")`;
	let url = this.execute_url + "?exp=" + expression + "&endpoint=" + endpoint + "&xplain_session=" + session_id;
	XPLAIN.AjaxHelper.get(url, "json", function(data){
		if (data.errors){
			return XPLAIN.alertErrors(data.errors);
		}
		thisWidget.state.addSetFromJson(data)

	});

	
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerExplorationBehavior = function(){
	var thisWidget = this;
	$('#derref').unbind().click(function(){
        thisWidget.ajax_derref();
    });    
    $('#search').unbind().click(function(){
        thisWidget.ajax_keyword_search();
    });    

	$("#seachbykeyword").unbind().keyup(function(e){
	
	    if(e.keyCode == 13)
	    {
	        thisWidget.ajax_keyword_search();
			$(this).val("");
	    }
	});

	$(".operation").click(function(){
		
		$(".help").empty();
		thisWidget.startOperation(this);
	});

	$('.param').click(function(){
		if($(this).is(':checkbox')){
			if($(this).is(':checked')){
				thisWidget.params_hash.put($(this).attr("param"), $(this).attr("param_value"));
			} else {
				thisWidget.params_hash.remove($(this).attr("param"));
			}
		} else {
			thisWidget.params_hash.put($(this).attr("param"), $(this).attr("param_value"));
		}
		if($(this).hasClass('filter_comparator')){
			debugger;
			$('.filter_comparator_active').removeClass('filter_comparator_active');
			$(this).addClass('filter_comparator_active');
		}
	
	});

    $('._clear').each(function(item){
        $(this).click(function(){
            thisWidget.clear();
        });
    });

    $('._equal').unbind().each(function(item){
		
        $(this).on("click", function(){
			debugger;

			thisWidget.params_hash.put('B', $('.SELECTED'));

            
			if (thisWidget.params_hash.get('operation') == 'intersect') 
				thisWidget.state.currentOperation = new SemanticExpression('A').intersection('B').expression;
			else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'diff') 
				thisWidget.state.currentOperation = new SemanticExpression('A').difference('B').expression;
			else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'union') {
				thisWidget.state.currentOperation = new SemanticExpression('A').union('B').expression;
			}			
            
		
			if (thisWidget.state.currentOperation.execute("json")){
				thisWidget.clear();
			}
        });
    });
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.selectSetAndFocus = function(setId){
    debugger;
    
    var $setWindow = $("[data-id='"+ setId + "']");
    $setWindow.ui_show();
    $setWindow.attr("top", "0px");
    $setWindow.attr("left", "0px");
    $setWindow.insertBefore($('#exploration_area .set').first())
    
    // $setWindow.fadeIn();
    $('.SELECTED').removeClass("SELECTED");
    $setWindow.addClass('SELECTED');

};

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.setParameter = function(widget){

    removeCSS($(widget).attr('exp'));
    $('.SELECTED').addClass($(widget).attr('exp'));
    $(widget).addClass($(widget).attr('exp'));
    this.params_hash.put($(widget).attr("id"), $('.SELECTED'));
    removeCSS('SELECTED');
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.startOperation = function(widget){

	if(this.params_hash.get("operation")){
		if(operationId == $(widget).attr("operation")){

			return;
		}
	
		var operationId = this.params_hash.get("operation");
		var inputParams = this.params_hash.get("A");
		var newSelected = $('.SELECTED')
		this.clear();
		if(newSelected.length){
			newSelected.addClass("SELECTED");
			this.params_hash.put("A", newSelected);
		} else {
			inputParams.addClass("SELECTED");
			this.params_hash.put("A", inputParams);
		}
	
		this.params_hash.put('operation', operationId)
	}

	this.setParameter(widget);
	$(".active").removeClass("active");
	var operationId = $(widget).attr("operation");

	this.params_hash.put("operation", operationId);
	$(widget).addClass("active");
	var inputParams = this.params_hash.get("A");
	
	if(inputParams.length == 0){
		alert("Choose at least one item/set to execute the operation!");
		return;
	}
	if(!$(widget).hasClass("set_operation")){
		var setId = $(inputParams[0]).attr("data-id");
		var operationName = $(widget).attr("operation");
		
		var operationController = eval("new XPLAIN.controllers."+operationName+"Controller(setId);");

		operationController.init();
	}
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.clear = function (){
	var paramsArray = ['A', 'B', 'S', 'P', 'O', "relation"];
    //Remove all CSS added to which resource selected.
    for (var index in paramsArray){
        this.removeCSS(paramsArray[index]);
    }
	$("#params_div").hide();
    this.removeCSS('SELECTED');
	this.removeCSS('active');
    this.params_hash = new Hashtable();
	$('[type=radio]').prop('checked', false);

	$('.filter_comparator_active').removeClass('filter_comparator_active');
	this.state.currentOperation = null;
	this.clearFacetModal();
	XPLAIN.activeControllers = new Hashtable();
};

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.clearFacetModal = function(){
	$('.filters').empty();
	$("#facetModal .modal-body").hide();
	// $("#facetModal .values_select").empty();
	$('#relation_checkbox').prop('checked', false);
};

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.removeCSS = function(klass){
	
    $('.' + klass).removeClass(klass);
	
};
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_view_profile = function(id) {
	var that = this;
	$.ajax({
		url: '/session/load_view_profile.json?id='+id ,
		type: 'get',
		contentType: 'application/json',
		success: function(data){
			that.edit_view_profile(data);
		},
		error: function(data){
			alert(data.responseText)
		}

	});

}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.list_view_profiles = function(){
	debugger
	var that = this;
	XPLAIN.AjaxHelper.get("/session/list_view_profiles.json", 'json', function(data){
		if (data.errors){
			return XPLAIN.alertErrors(data.errors);
		}
		debugger
		$('#list_profiles_modal ul').empty();
		data.profiles.forEach(function(profile){

			var profile_html = $('<button type="button" class="list-group-item list-group-item-action">' + profile.name +'</button>');
			profile_html.click(function(event){
				that.load_view_profile(profile.id)

			});
			
			$('#list_profiles_modal ul').append(profile_html);
			$('#new_profile_btn').click(function(e){
				
				$('#list_profiles_modal').modal('hide');
				that.edit_view_profile();
			});
			
		});
	});
	$('#list_profiles_modal').modal('show');
	

};

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.edit_view_profile = function(data){
	$("#input_profile_name").val("");
	$(".labels_for_type").remove();
	$(".text_for_items").remove();

	const labels_by_type_div = `
		<div class="form-group row feature labels_for_type">
			<div class="form-group col-md-4">
				<label for="type_id">Type ID</label>
				<input type="text" class="form-control col-sm-2 type_id" placeholder="">
			</div>
			<div class="form-group col-md-4">
				<label for="relations_ids">Label Relation ID</label>
				<input type="text" class="form-control col-sm-2 relations_ids" placeholder="">
			</div>
		</div>
	`;

	const text_for_items_div = `
		<div class="form-group row feature text_for_items">
			<div class="form-group col-md-4">
				<label for="item">Item ID</label>
				<input type="text" class="form-control col-sm-2 item_id" placeholder="">
			</div>

			<div class="form-group col-md-4">
				<label for="input_name">Label</label>
				<input type="text" class="form-control col-sm-2 input_label" placeholder="">
			</div>

			<div class="form-group col-md-4">
				<label for="input_name">Label for inverse relation </label>
				<input type="text" class="form-control col-sm-2 inverse_input_label" placeholder="">
			</div>

		</div>			
	`;
	var add_form_group = function(e){
		e.preventDefault()
		e.stopPropagation()
		
		var $feature_div;

		if ($(this).attr("id") === "label_for_type_add_btn"){
			$feature_div = $(labels_by_type_div);
		} else {
			$feature_div = $(text_for_items_div);
		}
		
		var form_group = $(this).parents('.profile_feature').first();
		// $feature_div.find('select').selectpicker();
		
		form_group.append($feature_div);
	}




	$('#label_for_type_add_btn').off('click').click(add_form_group);
	$('#text_for_item_add_btn').off('click').click(add_form_group);
	if (data){
		
		$('#input_profile_name').val(data.name);

		for (var key in data.labels_by_type_dict){
				
			if(data.labels_by_type_dict.hasOwnProperty(key)){ 
				
				var relations = data.labels_by_type_dict[key]
				var $div = $(labels_by_type_div);
				$div.find(".type_id").val(key);
				$div.find(".relations_ids").val(relations.join("; "));
				$(".profile_types").append($div);
			
			}
		}

		for (var key in data.item_text_dict){
			
			if(data.item_text_dict.hasOwnProperty(key)){ 
				var text = data.item_text_dict[key]
				var $div = $(text_for_items_div);
				$div.find(".item_id").val(key)
				$div.find(".input_label").val(text);
				$(".profile_items").append($div);
			}
		}

		for(var key in data.inverse_relation_text_dict){
			if(data.inverse_relation_text_dict.hasOwnProperty(key)){
				var text = data.inverse_relation_text_dict[key]
				var $div = $(text_for_items_div);
				$div.find(".item_id").val(key)
				$div.find(".inverse_input_label").val(text);
				$(".profile_items").append($div);
			}
		}

	}

	$('#view_profile_modal').modal('show');
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.save_view_profile = function(){
	var thisWidget = this;
	var type_config = {
		id: $('#input_profile_name').val(),
		name: $('#input_profile_name').val(),
		labels_by_type_dict: {},
		item_text_dict: {},
		inverse_relation_text_dict: {}
	}
	debugger
	if (!type_config.name) {
		return alert("Please enter a valid name for the profile!");
	}

	$('#view_profile_modal .labels_for_type').each(function(){
		var selected_type = $(this).find(".type_id").val();
		if (!selected_type){
			return;
		}

		var relations = []
		$(this).find(".relations_ids").val().split(";").forEach(function(r){
			relations.push(r.trim());
		});

		if (relations.length){
		    type_config.labels_by_type_dict[selected_type.trim()] = relations
		}
		
	});

	$('#view_profile_modal .text_for_items').each(function(){
		var selected_item = $(this).find(".item_id").val();
		if (!selected_item){
			return;
		}
		var text = $(this).find(".input_label").val();
		var inverse_text = $(this).find(".inverse_input_label").val();
		if (text){
		    type_config["item_text_dict"][selected_item] = text.trim();
		}
		
		if (inverse_text) {
			type_config["inverse_relation_text_dict"][selected_item] = inverse_text.trim();
		}

		debugger
	});
	console.log(type_config);


	let xplain_session = $("#session_name").data("sessionId");
	$.ajax({
		url: '/session/save_profile.json' + '?xplain_session=' + xplain_session,
		type: 'post',
		dataType: 'json',
		contentType: 'application/json',
		success: function(data){
			debugger
			thisWidget.reload_current_session();
		},
		error: function(data) {
			debugger
			alert("Something went wrong while saving the profile: "+ data.responseText)

		},
		data: JSON.stringify(type_config)
	});


}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.setup_and_show_namespaces_modal = function(){

	var add_ns = function(ns_prefix, ns_uri){       
		var $first_row = $('#namespace_modal .row').first();

		cloned_prefix_uri_row = $first_row.clone();
		$(cloned_prefix_uri_row).find(".ns-prefix").val(ns_prefix);
		$(cloned_prefix_uri_row).find(".ns-uri").val(ns_uri);
		$(cloned_prefix_uri_row).find(".ns-add-btn").removeClass("ns-add-btn").addClass("ns-remove-btn");
		$(cloned_prefix_uri_row).find(".glyphicon-plus").removeClass("glyphicon-plus").addClass("glyphicon-remove");
		$first_row.after(cloned_prefix_uri_row);
		$(cloned_prefix_uri_row).find(".ns-remove-btn").off('click').click(function(){
			$(this).parents('.row').remove();
		});
	};

	var validate_ns = function($ns_row){
		return ($ns_row.find(".ns-prefix").val() && $ns_row.find(".ns-uri").val());
	};

	var save_namespace_list = function(){
		var ns_json = {};
		var has_invalid_ns = false;
		$('#namespace_modal .row').first().siblings().each(function(){
			if(validate_ns($(this))){
				var prefix = $(this).find(".ns-prefix").val();
				var uri = $(this).find(".ns-uri").val();                
				ns_json[prefix] = uri;
			} else {
				has_invalid_ns = true;
			}

		});

		if(!has_invalid_ns) {
			$.ajax({
			  type : "POST",
			  url :  '/session/namespace',
			  dataType: 'json',
			  contentType: 'application/json',
			  data : JSON.stringify({"namespace_list": ns_json})
			});

			$('#namespace_modal').modal('hide');            
		} else {
			alert("There are some invalid namespaces, please correct before saving!");
		}

	};

	$('#namespace_modal .row').first().find(".ns-add-btn").off("click").click(function(){
		var $new_ns_row = $(this).parents('.row');
		if (validate_ns($new_ns_row)){
			add_ns($new_ns_row.find(".ns-prefix").val(), $new_ns_row.find(".ns-uri").val());
			$new_ns_row.find(".ns-prefix").val("");
			$new_ns_row.find(".ns-uri").val("");
		} else {
			alert("You should provide a valid prefix and URI for the namespace!");
		}
	});

	XPLAIN.AjaxHelper.get("/session/namespace.json", "json", function(data){

		$('#namespace_modal .row').first().siblings().remove();

		for (var i in data){
			add_ns(data[i].prefix, data[i].uri);    
		}
		$('#namespace_modal').modal('show');
	});

	$('#namespace_modal #save_ns_btn').off("click").click(function(){
		save_namespace_list();
	});
};

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.setup_and_show_endpoint_modal = function(){

	var add_endpoint = function(url, named_graph, is_blz_graph){       
		var div = "<div class=\"row\">";
		div += "<input class=\"blz_graph\" type=\"hidden\">";
		div += "<div class=\"col-md-2\">";
		div += "<label class=\"form-check-label url\"></label>"
		div += "</div>"
		div += "<div class=\"col-md-2\">";
		div += "<label class=\"form-check-label named_graph\" ></label>"
		div += "</div>"
		div += "<div class=\"col-md-2\">"
		div += "<div class=\"form-check\">"
		div += "<input type=\"checkbox\" class=\"form-check-input\">"
		div += "</div></div></div>"

		

		cloned_prefix_uri_row = $(div);		
		$(cloned_prefix_uri_row).find(".url").text(url);
		$(cloned_prefix_uri_row).find(".named_graph").val(named_graph);
		if (is_blz_graph){
			$(cloned_prefix_uri_row).find(".blz_graph").val("true");
		}
		debugger;

		$('#endpoint_modal hr').last().after(cloned_prefix_uri_row);

		$(cloned_prefix_uri_row).find(".form-check-input").off('click').click(function(){			
			debugger;
			if($(this).is(':checked')){
				$('#endpoint_modal #input_url').val($(this).parent().parent().parent().find(".url").text());
				$('#endpoint_modal #ngraph_uri').val($(this).parent().parent().parent().find(".named_graph").val());

				$("#endpoint_modal #blazegraph_search_idx").prop("checked", $(this).parent().parent().parent().find(".blz_graph").val() == "true");
			}
		});
	};


	XPLAIN.AjaxHelper.get("/session/endpoint.json", "json", function(data){

		$('#endpoint_modal .row').remove();
		debugger;

		for (var i in data){
			add_endpoint(data[i].url, data[i].named_graph, data[i].is_blz_graph);    
		}
		$("#endpoint_modal [name=http-method][value=post]").first().prop('checked', true);
		$('#endpoint_modal').modal('show');
	});
	
};

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.addChildView = function(viewClass){
	
};

XPLAIN.states.WorkspaceState = function(){ 
	XPLAIN.states.State.call(this)
	this.sets = [];
	this.currentOperation = null;
};

XPLAIN.states.WorkspaceState.prototype = Object.create(XPLAIN.states.State.prototype);

XPLAIN.states.WorkspaceState.prototype.sets = [];

XPLAIN.states.WorkspaceState.prototype.currentOperation = null;

XPLAIN.states.WorkspaceState.prototype.addSetFromJson = function(setJson){
	const viewAlreadyAdded = $('[data-id="'+setJson.id+'"]').length;
	
	if (viewAlreadyAdded){
		$('[data-id='+setJson.id+']').remove();
		
		XPLAIN.graph.removeSet(setJson.id);
		
	}

	this.addSetState(new XPLAIN.states.SetState(setJson));
};

XPLAIN.states.WorkspaceState.prototype.addSetState = function(setState){
	var thisState = this;
	var updateFunction = function(){
		thisState.sets.push(setState);
		return setState;
	};
	
	this.change('addSet', updateFunction);
};

XPLAIN.states.WorkspaceState.prototype.deleteSetState = function(setId){
	var url = "/session/delete_set?id=" + setId;
	var thisState = this;
	XPLAIN.AjaxHelper.get(url, "json", function() {
		thisState.change('deleteSet', function(){ 
			var i = 0;
			debugger;
			for(var i = 0; i < thisState.sets.length; i++){
				if (thisState.sets[i].setJson.id == setId){
					thisState.sets.splice(i);
				}
			}
			return {removedSet: setId};
		});
	});
	
};