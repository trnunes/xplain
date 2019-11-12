XPLAIN.widgets = XPLAIN.widgets || {}
XPLAIN.states = XPLAIN.states || {}

XPLAIN.widgets.DefaultWorkspaceWidget = function(workspaceState){
	
	
	XPLAIN.widgets.Widget.call(this, null, workspaceState);
	this.params_hash = new Hashtable();
	
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype = Object.create(XPLAIN.widgets.Widget.prototype)

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.build = function(){
	
	XPLAIN.widgets.Widget.prototype.build.call(this);
	this.registerBehavior();
}
	
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerBehavior = function(){
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
	if ($('#exploration_area').find('.set').length > 0) {
	
		widget.html.insertBefore($('#exploration_area').find('.set').first());
				
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
		XPLAIN.AjaxHelper.get("/session/execute.json?exp="+ expression, "json", function(data){
			
			
			thisWidget.state.addSetFromJson(data);
		});
	});

	$("#all_relations").unbind().click(function(){
	    var expression = "Xplain::ExecuteRuby.new(code: 'Xplain::SchemaRelation.new(id: \"relations\", server: @server).image.sort_asc!')"
        XPLAIN.AjaxHelper.get("/session/execute.json?exp="+ expression, "json", function(data){			
			thisWidget.state.addSetFromJson(data);
		});
	});
    
    $('#set_endpoint_btn').click(function () {
        var endpoint_url = $('#input_url').val().trim();
        var named_graph_uri = $('#ngraph_uri').val().trim();
        var http_method = $("#endpoint_modal [name=http-method]:checked").val();
        var max_items_per_query = $("#endpoint_modal #max_items").val().trim();
        
        // mounting endpoint config url
        var url = "/session/set_endpoint?method="+http_method+"&items_limit=" + max_items_per_query + "&graph=" +  encodeURIComponent(endpoint_url)+ "&named_graph=" +  encodeURIComponent(named_graph_uri);

        if ($("#endpoint_modal #blazegraph_search_idx:checked").size()){
            url += "&class=BlazegraphDataServer";            
        } else {
        	url += "&class=Xplain::RDF::DataServer";
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

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_session = function(){
	var thisWidget = this;
	debugger;
	var session_name = $("input:radio[name=radio_session]:checked").parent().text();
	XPLAIN.AjaxHelper.get("/session/load_session.json?name=" + session_name, "json", function(data){
		
		$('.set').find("._remove").click()
		data.sets.forEach(function(setData){
			debugger;
			thisWidget.state.addSetFromJson(setData);
		});
		$("#session_name").text(session_name);
		$("#endpoint_url 	").text(data.server);
		
	});
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.load_session_by_id = function(id){
    var thisWidget = this;
    debugger;
    
    XPLAIN.AjaxHelper.get("/session/load_session.json/" + id, "json", function(data){
        debugger;
        $('.set').find("._remove").click()
        data.sets.forEach(function(setData){
            thisWidget.state.addSetFromJson(setData);
        });
        
        $("#session_name").text(data.name);
        
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

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.close_session = function(){
	var thisWidget = this;
    XPLAIN.AjaxHelper.get("/session/close", "json", function(data){
        
        $('.set').find("._remove").click()
        
        $("#session_name").text("Unnamed");
        
    });

}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.save_session_as = function(){
	var thisWidget = this;
	debugger;
	var name = prompt("Save session: please enter the session name", "").trim();
	if (!name){
		alert("The session name cannot be empty!");
		return
	}
	$("#session_name").text("Saving session...");
	this.save_session(name);
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.save_session = function(name){

	var thisWidget = this;
	debugger;
	var save_url = "/session/save_session.json";
	var session_text = $("#session_name").text();
	if (session_text.indexOf("Unnamed") >= 0 ) {
		return this.save_session_as();
	}

	if (name) {
		name = name.trim();
		save_url += "?name=" + name;
		session_text = name;

	} 
	XPLAIN.AjaxHelper.get(save_url, "json", function(data){
		debugger;
		alert("Session has been saved!");
		$("#session_name").text(session_text);
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

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.ajax_keyword_search = function(){
	var inputValues = $("#seachbykeyword").val().trim();
	

	if (inputValues === '') {
		$("#seachbykeyword").fadeOut(50).promise().done(function () {
	        $(this).toggleClass("blink-class").fadeIn(50);
	    });

		alert("Please, type one or more keywords!");
		return this;
	} else {
		new KeywordSearch([inputValues]).execute("json");
	}
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.ajax_derref = function(){
	var thisWidget= this
	var inputValues = $("#seachbykeyword").val().trim();
	

	if (inputValues === '') {
		$("#seachbykeyword").fadeOut(50).promise().done(function () {
	        $(this).toggleClass("blink-class").fadeIn(50);
	    });

		alert("Please, type the URI to derreferentiate!");
		return this;
	} else {

		var expression =  "Xplain::ExecuteRuby.new(code: 'Xplain::ResultSet.new(nodes: [Xplain::Entity.new(\""+inputValues+"\")])')";		
		XPLAIN.AjaxHelper.get("/session/execute.json?exp="+ expression, "json", function(data){
			
			
			thisWidget.state.addSetFromJson(data);
		});
	}
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerExplorationBehavior = function(){
	var thisWidget = this;
    $('#search').unbind().click(function(){
        thisWidget.ajax_keyword_search();
    });  
	$('#derref').unbind().click(function(){
        thisWidget.ajax_derref();
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

    $('._export').unbind().click(function(){
    	var set_id = $('.SELECTED.set').attr("data-id");
    	debugger
    	XPLAIN.AjaxHelper.get("/session/export?id="+set_id, "json", function(data){
			var blob = new Blob([data], { type: 'text/plain' });
			var link = document.createElement('a');
			link.href = window.URL.createObjectURL(blob);
			link.download = "export.txt";

			document.body.appendChild(link);

			link.click();

			document.body.removeChild(link);
    		
    		
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

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.show_endpoint_modal = function(){
	$("#endpoint_modal [name=http-method] [value=post]").first().prop('checked', true);
	$('#endpoint_modal').modal('show');
};

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
		return ($ns_row.find(".ns-prefix").val().trim() && $ns_row.find(".ns-uri").val().tim());
	};

	var save_namespace_list = function(){
		var ns_json = {};
		var has_invalid_ns = false;
		$('#namespace_modal .row').first().siblings().each(function(){
			if(validate_ns($(this))){
				var prefix = $(this).find(".ns-prefix").val().trim();
				var uri = $(this).find(".ns-uri").val().trim();                
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
			add_ns($new_ns_row.find(".ns-prefix").val().trim(), $new_ns_row.find(".ns-uri").val().trim());
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
}

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