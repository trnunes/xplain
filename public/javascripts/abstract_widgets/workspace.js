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
	var addedSetState = eventJson.data
	var abstractSetWidget = new XPLAIN.widgets.SetWidget(this, addedSetState);

	var setWidget = XPLAIN.widgets.createView(abstractSetWidget, addedSetState.setJson);
	debugger
	abstractSetWidget.build();
	XPLAIN.graph.addSet(addedSetState.setJson);
	this.addWidgetToView(setWidget)
	
}

	
XPLAIN.widgets.DefaultWorkspaceWidget.prototype.registerLandmarkHandlers = function(){
	var thisWidget = this;
	$("#all_types").unbind().click(function(){
		debugger;
		XPLAIN.AjaxHelper.get("/session/all_types.json", "json", function(data){
			debugger
			data.set.intention = "All Types";			
			thisWidget.state.addSetFromJson(data.set);
		});
	});

	$("#all_relations").unbind().click(function(){
		XPLAIN.AjaxHelper.get("/session/all_relations.json", "json", function(data){
			data.set.intention = "All Relations";
			XPLAIN.SetController.appendToWorkspace(data.set);
		});
	});
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
		debugger;
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

            if (!thisWidget.state.currentOperation){
	            if (thisWidget.params_hash.get('operation') == 'intersect') 
	                thisWidget.state.currentOperation = new SemanticExpression('A').intersection('B').expression;
	            else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'diff') 
	                thisWidget.state.currentOperation = new SemanticExpression('A').difference('B').expression;
				else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'union') {
	                thisWidget.state.currentOperation = new SemanticExpression('A').union('B').expression;
				}			
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
		debugger;
		var operationController = XPLAIN.activeControllers.get(operationName) || eval("new XPLAIN.controllers."+operationName+"Controller(setId);");

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
	debugger;
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