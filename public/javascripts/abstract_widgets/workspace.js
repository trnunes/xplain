XPLAIN.widgets = XPLAIN.widgets || {}
XPLAIN.states = XPLAIN.states || {}

XPLAIN.widgets.DefaultWorkspaceWidget = function(workspaceState){
	
	debugger
	XPLAIN.widgets.Widget.call(this, null, workspaceState);
	this.params_hash = new Hashtable();
	
}

XPLAIN.widgets.DefaultWorkspaceWidget.prototype = Object.create(XPLAIN.widgets.Widget.prototype)

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.build = function(){
	debugger
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

	
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerLandmarkHandlers = function(){
	var thisWidget = this;
	$("#all_types").unbind().click(function(){
		debugger;
		var expression = "Xplain::SchemaRelation.new(id: \"has_type\").image.sort_asc!"
		XPLAIN.AjaxHelper.get("/session/execute.json?exp="+ expression, "json", function(data){
			
			
			thisWidget.state.addSetFromJson(data);
		});
	});

	$("#all_relations").unbind().click(function(){
	    var expression = "Xplain::SchemaRelation.new(id: \"relations\").image"
        XPLAIN.AjaxHelper.get("/session/execute.json?exp="+ expression, "json", function(data){			
			thisWidget.state.addSetFromJson(data);
		});
	});
    
    $('#set_endpoint_btn').click(function () {
        var endpoint_url = $('#input_url').val();
        var http_method = $("#endpoint_modal [name=http-method]:checked").val();
        var max_items_per_query = $("#endpoint_modal #max_items").val();
        
        // mounting endpoint config url
        var url = "/session/set_endpoint?method="+http_method+"&items_limit=" + max_items_per_query + "&graph=" +  encodeURIComponent(endpoint_url);

        if ($("#endpoint_modal #blazegraph_search_idx:checked").size()){
            url += "&class=BlazegraphDataServer";            
        } else {
        	url += "&class=RDFDataServer";
        }
        debugger;
        if (endpoint_url) {
            XPLAIN.AjaxHelper.get(url);
        }
       
     });    


}
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.ajax_keyword_search = function(){
	var inputValues = $("#seachbykeyword").val();
	

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

XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerExplorationBehavior = function(){
	var thisWidget = this;
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
		debugger;
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
