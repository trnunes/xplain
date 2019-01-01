XPLAIN.activeControllers = new Hashtable()
XPLAIN.getController = function(operationName){
	XPLAIN.activeControllers.get(operationName);
};

XPLAIN.controllers = XPLAIN.controllers || {};

XPLAIN.controllers.AbstractRelationsTreeController = function(){};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.init = function(){
	debugger;
	this.setIdOfValuesList = "";
	
	this.treeDivSel = this.viewSelector + " .relation_area";
	this.relatedSetsDiv = this.viewSelector + " .related_sets_div"
	this.relatedSetsSel = this.viewSelector + " .related_sets_select"
	this.relatedSetAct = this.viewSelector + " .related_set_activator"
	this.valuesListSel = this.viewSelector + " .values_select";	
	this.positionDivSel = this.viewSelector + " .position";
	this.positionRadiosSel = this.positionDivSel +" .position_radio_input";
	this.treeActivatorRadioSel = this.viewSelector + " .relation_tree_activator";
	this.selectedRelations = [];
	this.treeParams = {allowMultipleSelection: false};
	
	this.registerBehavior();
	this_controller = this;

	// $(this.viewSelector).off('hide.bs.modal').on("hide.bs.modal", function(){
	// 	if(this.tree){
	// 		debugger;
	// 		this_controller.selectedRelations = this.tree.getSelection();
	// 		this.tree.hide();
	// 	}
	//
	// });
	
	$(this.viewSelector + " .clear").click(function(){

		debugger;
		if(this_controller.tree){
			debugger;
			this_controller.selectedRelations = this_controller.tree.getSelection();
			this_controller.tree.hide();
		}
		$(this_controller.valuesListSel).select2();
		$(this_controller.valuesListSel).select2('val', null);
		$(this_controller.valuesListSel).empty();
		$(this_controller.relatedSetsDiv).hide();
		$(".help").empty();
		clear();
	});
	
	$(this_controller.viewSelector + " .exec").off("click").click(function(){
		this_controller.dismiss();
		debugger;
		if(XPLAIN.activeWorkspaceState.currentOperation.execute("json")){
			clear();
			XPLAIN.activeControllers = new Hashtable();
			$(this_controller.viewSelector).parents('.modal').modal('hide');
		}
	});

	$(this.viewSelector +  " #image").prop("checked", true);
	if(this.tree){
		this.tree.destroy();
	}
	$(this.treeDivSel).empty();

	$(".help").empty();
	//TODO correct the level selection
	if(XPLAIN.SetController.countLevels(this.setId) > 1){
		$(this.positionDivSel).show();
		this.radioAddLevels();
	} else {
		$(this.positionDivSel).hide();
	}
	
	if($(this.treeActivatorRadioSel).length){
    	$(this.treeActivatorRadioSel).prop("checked", false);
    	this.handlePositionChanged();
	} else {
		this.loadRelationsTree();
	}
	
	$(this.viewSelector + " .relation_tree_activator").prop("checked", false)
	$(this_controller.relatedSetsDiv).hide();
	$(this.viewSelector + ' .values_select').val([]);
	$(this.viewSelector + ' .values_select').empty();

	$(this.viewSelector).modal("show");
	this.initController();
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.getLevel = function(){
	debugger;
	return parseInt($(this.positionRadiosSel + ":checked").attr('param_value'));

};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.radioAddLevels = function(){
	var lastRadio = $(this.positionDivSel).find('.radio').first().clone();
	
	$(this.positionDivSel + " .radio").remove();
	for (var i=1; i<=XPLAIN.SetController.countLevels(this.setId); i++)
	{
		var clonedRadio = lastRadio.clone();
		clonedRadio.find('input').attr('name', this.setId + "_radio");
		clonedRadio.find('input').attr("param_value", i + 1);
		clonedRadio.find('span').text("Level " + i);
		$(this.positionDivSel).append(clonedRadio);
	
	}
	debugger;
	clonedRadio.find('input').prop("checked", true);

	$(this.positionDivSel + " .position_radio_input").change(function(){
		debugger;
		if(this_controller.tree){
			this_controller.loadRelationsTree($(this).attr("param_value"));
		}
		
	})

};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.dismiss = function(){
	if(this.tree){
		debugger;
		this_controller.selectedRelations = this.tree.getSelection();
		this.tree.hide();
	}
	XPLAIN.activeWorkspaceState.currentOperation = this.buildOperation();

};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.getSelection = function(){
	if(this.tree){
		return this.tree.getSelection();
	}
	return [];
};


XPLAIN.controllers.AbstractRelationsTreeController.prototype.buildOperation = function(){};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.registerBehavior = function(){
	
	$(this.treeActivatorRadioSel).unbind().change(function() {
		debugger;
		$(this_controller.valuesListSel).select2();
		$(this_controller.valuesListSel).select2('data', null);
		$(this_controller.valuesListSel).empty();
        if(this.checked && $(this).hasClass("relation_tree_activator")) {
				
			this_controller.loadRelationsTree(this_controller.getLevel());

			$(this_controller.relatedSetsDiv).hide()
			
        } else {
			if(this_controller.tree){
				this_controller.tree.hide();
				this_controller.handlePositionChanged();
			}
			if ($(this).hasClass("related_set_activator")){
				this_controller.showRelatedSetsList();
			} else if($(this).hasClass("by_domain_act")){
				var resultedFromSetId = XPLAIN.SetController.getResultedFrom(this_controller.setId);
				if (this_controller.setId){
					if (resultedFromSetId){
						this_controller.updateValuesList(XPLAIN.SetController.getExtension(resultedFromSetId), XPLAIN.SetController.getTitle(resultedFromSetId));
					}
				}
			} else {
				$(this_controller.relatedSetsDiv).hide();
			}
        }
    });
	
	$(this.positionRadiosSel).unbind().change(function(){
		this_controller.handlePositionChanged();
	});
	
	this.registerControllerBehavior();
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.beforePivotBranchSelected = function(pivot){

};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.handleBranchSelected = function(pathRelation){
	
	var relation = pathRelation.relations[pathRelation.relations.length - 1];
	var expression =  "Xplain::ResultSet.find_by_node_id(\""+relation.data.setNode+"\")";
	expression += ".first.resulted_from.first";
	var pivot = new Pivot(new Expression(expression));
	pivot.visual = true;
	debugger;
	var path_has_single_relation = pathRelation.relations.length <= 1;
	if (path_has_single_relation){
		pivot.position = this_controller.getLevel();
	}

	pivot.addRelation(relation);
	this_controller.beforePivotBranchSelected(pivot);

	//TODO put a limit to the pivot operation
	pivot.uniq().execute("json", function(data){
		debugger;
		this_controller.updateValuesList(data.extension, data.id);
	});
};


XPLAIN.controllers.AbstractRelationsTreeController.prototype.handlePositionChanged = function(){
	debugger;
	if(this.getSelectedPosition() == "1"){
		this.showDomain();
		$(this.viewSelector + " #by_image_div").show();
	} else {
		$(this.viewSelector + " #by_image_div").hide();
		this.showImage();
	}
	
	if(this_controller.positionChanged){
		this_controller.positionChanged(this.getSelectedPosition());
	}
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.getSelectedPosition = function(){
	return $(this.viewSelector + " .position input[type='radio']:checked").attr('param_value') || "2";
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.handleBranchOpened = function(relation){
	debugger;
	var expression =  "Xplain::ResultSet.find_by_node_id(\""+relation.li_attr.setNode+"\")";
	expression += ".first.resulted_from.first";
	var pivot = new Pivot(new Expression(expression));
	pivot.visual = true;
	pivot.addRelation(new Relation(relation.li_attr));
	this_controller.beforePivotBranchSelected(pivot);

	var relation_from_origin_set = (relation.li_attr.resultedFrom && relation.li_attr.resultedFrom.length && relation.li_attr.resultedFrom[0].id == this_controller.setId);
	if(relation_from_origin_set) {
		pivot.position = this_controller.getLevel();
	}

	var relationsPivot = new Pivot(pivot);
	relationsPivot.visual = true;
	relationsPivot.limit = pivot.limit;
	relationsPivot.addRelation(new Relation({item: "relations"}));

	relationsPivot.execute("json", function(data){
	debugger;
		var relations_hash = new Hashtable();
		var items = data.extension;
		for (var i in items){
			this_controller.tree.addItem(relation, items[i]);
		}
	});
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.loadRelationsTree = function(level){

	this.tree = new XPLAIN.views.RelationPathTree(this.setId, $(this.treeDivSel), this.treeParams);
	var levelExpr = "";
	if (level) {
		levelExpr = "(level: "+level+")";
	}
	var expression = "Xplain::ResultSet.load(\""+this.setId+"\").pivot(visual: true)"+levelExpr+"{ relation \"relations\"}.execute"
	
	this.tree.loadData(expression);

	this.tree.onBranchSelected(this.handleBranchSelected);
	this.tree.onBranchOpened(this.handleBranchOpened);
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.showRelatedSetsList = function(){
	debugger;
	$(this.relatedSetsDiv).show();
	var relatedSets = XPLAIN.SetController.getInputSets(this_controller.setId);
	
	var setData = relatedSets.map(function(s){ return {id: s.id, text: s.title}});
	if(setData.length > 0){
		debugger;
		$(this_controller.viewSelector + ' .values_select').val(relatedSets[0].data.extension[0]);
		//TODO correct to show all related sets
		this_controller.updateValuesList(relatedSets[0], setData[0].id);
		
	}
	

	$(this_controller.relatedSetsSel).empty();
	$(this_controller.relatedSetsSel).select2({
		data: setData,
		placeholder: "Select a Set",
		allowClear: true
	});
	
	$(this_controller.relatedSetsSel).on('change', function(){
		this_controller.updateValuesList(XPLAIN.currentSession.getSet(this.value).data.extension, XPLAIN.currentSession.getSet(this.value).getId())
	});
	
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.updateValuesList = function(data, setId){
	var items = data;
	debugger;
	

	this.setIdOfValuesList = setId;
	that = this;
	$(this.viewSelector + ' .values_select').select2({
		id: function(bond){debugger; return bond;},
		ajax: {
			transport: function(params, success, failure){
			  if(!params.data.term){
			  	
			  	XPLAIN.AjaxHelper.get("/session/render_page.json?set=" + setId + "&page=" + (params.data.page || 1), "json", function(data){
					
						success(data, (params.data.page || 1));
					
				});
				return;
			  }

			  

			  XPLAIN.AjaxHelper.get("/session/search.json?set=" + setId + "&str=" + params.data.term, "json", function(data){
			  	debugger;
			  	success(data, (params.data.page || 1));
			  });
			  
			},
			
			processResults: function(data, params) {
				var selectData = data.extension.map(function(item){return {id: item.id, text: item.text, item_data: item}});
				var pages_count = data.pages_count;
				if(selectData.length > 0){
					$(this.viewSelector + ' .select2').val(selectData[0].id).trigger('change');
				}
				debugger;
				return {
					results: selectData,
					pagination: {
						more: (((params.page || 1) * 20) <= data.size)
				    }
				 };
			},
  		    dropdownAutoWidth : true,
		    width: '100%',
			escapeMarkup: function (markup) { return markup; },
			placeholder: "Select a value",
			allowClear: true,
			minimumInputLength: 3,
			cache: false,

		}
	});
	
// 	for(var i in items){
// 		var option = new Option(items[i].text, items[i].id, true, true);
// 		$(option).data('item_data', items[i]);
// 		$(this.viewSelector + ' .values_select').append(option);
// 	}
// 	if(items.length > 0){
// 		$(this.viewSelector + ' .values_select').val(items[0].text);
		
// 	}

	debugger;
	
	
	$(this.viewSelector + ' .select2 span .select2-selection__rendered').text('Click to inspect/select items');
	

	
	
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.showDomain = function(){
    var extension = XPLAIN.SetController.getExtension(this.setId);
	this.updateValuesList(extension, this.setId);

};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.showImage = function(){
	this.updateValuesList(XPLAIN.SetController.getLeaves(this.setId), this.setId);
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.initController = function(){};
XPLAIN.controllers.AbstractRelationsTreeController.prototype.registerControllerBehavior = function(){};
XPLAIN.controllers.AbstractRelationsTreeController.prototype.handleValueSelection = function(value){};


XPLAIN.controllers.RankController = function(setId){
	this.setId = setId;
	this.setIdOfValuesList = "";
	this.viewSelector = "#rankModal";
	this.orderRadiosSel = this.viewSelector +" input[name='order']";
	this.rankFunctionSel = this.viewSelector + " input[name='radio_strategy']";
	this.valuesLimit = 10;
	var this_controller = this;
	
	this.initController = function(){
		debugger;
		$(this.viewSelector + " #alpha_rank").prop("checked", true);
		$(this.viewSelector + " #asc").prop("checked", true);
		$(this.viewSelector +  " #domain").prop("checked", true);
	},
	
	this.registerControllerBehavior = function(){
		$(this.rankFunctionSel).change(function(e){
			debugger;
			if($(this).attr("param_value") == "by_image"){
				$(this_controller.valuesListSel).select2('destroy');
				$(this_controller.valuesListSel).empty();
				$(this_controller.valuesListSel).select2({
					//TODO correct leaves method
					data: XPLAIN.SetController.getLeaves(this.setId),
					placeholder: "Select a Set",
					allowClear: true
				});
				
			}	
		});
	},
	
	this.buildOperation = function(){
		var rank = new Rank(new Load(this.setId));
		rank.order = $(this.orderRadiosSel + ":checked").attr("param_value") || "ASC";
		if (!($(this.rankFunctionSel + ":checked").attr("param_value") == "alpha_rank")){
			rank.functionParams = {function: $(this.rankFunctionSel + ":checked").attr("param_value")};
		}
		
		rank.position = this.getLevel();
		if(this.selectedRelations.length){
			rank.functionParams.relation = this.selectedRelations[0];
		}		
		return rank;
	}
	
};

XPLAIN.controllers.RankController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();

XPLAIN.controllers.RefineController = function(setId){
	this.setId = setId;
	this.viewSelector = "#facetModal";
	this.buttonAddFilterSel = this.viewSelector + " #button_add_filter";
	this.selectComparatorSel = this.viewSelector + " #select_comparator";
	this.connectorSel = this.viewSelector + " input[name='conn']";
	this.connectorsDivSel = this.viewSelector + " #facet_conn"
	this.filtersDivSel = this.viewSelector + " .filters";
	this.filterCloseSpanSel = this.viewSelector + " span .close"
	var this_controller = this;
	
	this.initController = function(){
		// this.showRelationsTree();
		XPLAIN.activeWorkspaceWidget.params_hash.put("FacetedRefine", true);
		XPLAIN.activeWorkspaceWidget.params_hash.put("operation", "refine");
		XPLAIN.activeWorkspaceWidget.params_hash.put("operator", "=");
		$('#eql_comp').addClass('filter_comparator_active');
		
		XPLAIN.activeWorkspaceState.currentOperation = new FacetedSearch(new Load(this.setId));
		
		$(this.selectComparatorSel).val("=");

		$(this.connectorsDivSel).hide();
		debugger;
		$(this.viewSelector + " .modal-body").show();
	},
	
	this.registerControllerBehavior = function(){
		$(this.buttonAddFilterSel).unbind().click(function(e){
			this_controller.addFilter();
		});

		$(this.selectComparatorSel).change(function(){
			this_controller.handleOperatorChanged($(this).val());
		});
	},
	
	this.handleOperatorChanged = function(operator){
		if(operator == "in"){
			var setData = XPLAIN.SetController.getAllSetsIdsAndTitles().map(function(s){ return {id: 'Xset.load("' + this.id + '")', text: this.title}});
			$(this.valuesListSel).select2('destroy');
			$(this.valuesListSel).empty();
			$(this.valuesListSel).select2({
				data: setData,
				placeholder: "Select a Set",
				allowClear: true
			});
		}
	},	
		
	this.removeFilter = function(){
		XPLAIN.activeWorkspaceState.currentOperation.removeFacet(this.selectedRelations, XPLAIN.activeWorkspaceWidget.params_hash.get('operator'), {item_type: $(value).attr("item_type"), datatype: $(value).attr("datatype"), item: value.id});
	},
	
	this.addFilter = function(){
		$(this.connectorsDivSel).show();
		var position = $(this.positionRadiosSel + ":checked").attr('param_value');
		//TODO review the boolean operator
		var booleanOperator = $(this.connectorSel + ":checked").attr('param_value') || "And";
		var values = $(this.valuesListSel).select2('data');
		var selectedRelations = this.getSelection();
		if(values.length == 0){
			return;
		}

		for(var i in values){
			value = values[i];
			var comparator = $($(this.selectComparatorSel).find(":selected")).val();

			var relation = null;
			var restriction = null;
			if(selectedRelations.length > 0){
				restriction = new RelationRestriction();
				restriction.relation = selectedRelations[0];
			} else {
				restriction = new Restriction();
			}

			restriction.operator = comparator;
			restriction.connector = booleanOperator;
			debugger
			restriction.value = new Item(value.item_data);
		
			restriction.position = position
			debugger
			XPLAIN.activeWorkspaceState.currentOperation.addRestriction(restriction);
			XPLAIN.activeWorkspaceState.currentOperation.connector = booleanOperator;
			XPLAIN.activeWorkspaceState.currentOperation.position = position;
			
		}
		this.updateFiltersTable();
		
	},
	
	this.updateFiltersTable = function(){
		var filter_div = "";
		
		filter_div += XPLAIN.activeWorkspaceState.currentOperation.toHtml()//.join("<tr class=\"filter_connector\"><td><span>" + XPLAIN.activeWorkspaceState.currentOperation.connector + "</span></td></tr>");
		$(this.filtersDivSel).html("<table>" + filter_div + "</table>");

		$(this.filterCloseSpanSel).click(function(e){
			debugger;
			var facet = $(this).attr("facet");
			var operator = $(this).attr("operator");
			var value = $(this).attr("facet_value");
			if(facet){
				XPLAIN.activeWorkspaceState.currentOperation.removeRelationRestriction(facet, operator, value);
			} else{
				XPLAIN.activeWorkspaceState.currentOperation.removeSimpleRestriction(operator, value);
			}
			
			var tableCell = $(this).parent().parent()
			if($(tableCell).prev().hasClass("filter_connector")){
				$(tableCell).prev().remove();
			} else if($(tableCell).parent().prev().hasClass("filter_connector")) {
				$(tableCell).parent().prev().remove();
			}
			if($(tableCell).next().hasClass("filter_connector")){
				$(tableCell).next().remove();
			} else if($(tableCell).parent().next().hasClass("filter_connector")) {
				$(tableCell).parent().next().remove();
			}

			$(tableCell).remove();
			if(XPLAIN.activeWorkspaceState.currentOperation.isEmpty()){
				$(this.connectorsDivSel).hide();
			}
		});
	},
	
	this.buildOperation = function(){
		return XPLAIN.activeWorkspaceState.currentOperation;
	}	
};
XPLAIN.controllers.RefineController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();

XPLAIN.controllers.PivotController = function(setId){
	this.setId = setId;
	this.viewSelector = "#pathModal";
	this.valuesLimit = 10;
	var this_controller = this;
	
	this.initController = function(){
		this.treeParams.allowMultipleSelection = true;
		XPLAIN.activeWorkspaceState.currentOperation = new Pivot(new Load(this.setId)).uniq();
		$(this_controller.viewSelector + " #group_by_domain").prop("checked", false);
	},

	this.beforePivotBranchSelected = function(pivot) {
		pivot.limit = 15;
	},
	
	this.buildOperation = function(){
		debugger;
		XPLAIN.activeWorkspaceState.currentOperation.relations = this_controller.selectedRelations;
		XPLAIN.activeWorkspaceState.currentOperation.position = this_controller.getLevel();
		if ($(this_controller.viewSelector + " #group_by_domain:checked").length) {
			XPLAIN.activeWorkspaceState.currentOperation.group_by_domain = true;
// 			XPLAIN.activeWorkspaceState.currentOperation.debug = true;
		}

		return XPLAIN.activeWorkspaceState.currentOperation;
	}	
};
XPLAIN.controllers.PivotController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();

XPLAIN.controllers.GroupController = function(setId){
	this.setId = setId;
	this.viewSelector = "#groupModal";
	var this_controller = this;
	this.operatorSel = this.viewSelector + " input[name='radio_strategy']";
	this.valuesLimit = 10;
	this.setSel = this.viewSelector + " #image_select";
	this.restrictGroupsCheckSel = this.viewSelector + " #restrict_groups_check";
	this.imageSelectDivSel = this.viewSelector + " #image_select_div";
	
	this.initController = function(){
		this.treeParams.allowMultipleSelection = true;
		
		XPLAIN.activeWorkspaceState.currentOperation = new Group(new Load(this.setId));
		
		$(this.setSel).empty();
		$(this.setSel).select2();
		$(this.restrictGroupsCheckSel).prop("checked", false);
		
		$(this.imageSelectDivSel).hide();
		
		XPLAIN.activeControllers.put('Group', this);
	},
	
	this.beforePivotBranchSelected = function(pivot) {
		pivot.limit = 50;
	},

	
	this.registerControllerBehavior = function(){
		$(this.operatorSel).change(function(){
			this_controller.handleOperatorChanged($(this));
		});
		debugger;
		$(this.restrictGroupsCheckSel).change(function(){
			debugger;
			if(this.checked){
				$(this_controller.imageSelectDivSel).show();
				this_controller.populateSetSelector();
			} else {
				$(this_controller.imageSelectDivSel).hide();
			}
		});
		
	},
	
	this.handleOperatorChanged = function($operator){
		XPLAIN.activeWorkspaceState.currentOperation.groupFunction = $operator.attr("param_value");
		
	},
	this.populateSetSelector = function(){

		var setData = XPLAIN.SetController.getAllSetsIdsAndTitles().map(function(s){ return {id: 'Xset.load("' + this.id + '")', text: this.title}});
		$(this.setSel).select2('destroy');
		$(this.setSel).empty();
		$(this.setSel).select2({
			data: setData,
			placeholder: "Select a Set",
			allowClear: true
		});

	},
	
	this.buildOperation = function(){
		var params = {function: "by_image", functionParams: this.selectedRelations};
		XPLAIN.activeWorkspaceState.currentOperation.params = params;
		return XPLAIN.activeWorkspaceState.currentOperation;
	}	
};
XPLAIN.controllers.GroupController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();

XPLAIN.controllers.MapController = function(setId){
	this.setId = setId;
	this.viewSelector = "#mapModal";
	this.functionsRadioSel = this.viewSelector + " input[name='radio_strategy']";
	this.functionDefinitionFormSel = this.viewSelector + " #function_form";
	this_controller = this;

	this.initController = function(){
		XPLAIN.activeWorkspaceState.currentOperation = new Map(new Load(this.setId));
		$(this.functionDefinitionFormSel).hide();
		

		$(this.functionsRadioSel).unbind().change(function(e){
			debugger;
			this_controller.handleFunctionChange($(this));
		});
		
		$(this.viewSelector + " .clear").click(function(){
			clear();
		});
	
		$(this_controller.viewSelector + " .exec").off().click(function(){
			debugger;
			this_controller.dismiss();
			
			if(XPLAIN.activeWorkspaceState.currentOperation.execute("json")){
				clear();
				$(this_controller.viewSelector).parents('.modal').modal('hide');
			}
		});
		
		$(this.viewSelector).modal("show");
		
		
	},
	this.beforePivotBranchSelected = function(pivot) {
		pivot.limit = 15;
	},

	
	this.handleFunctionChange = function($radioOption){
		if($radioOption.attr("param_value") == "user_defined"){
			$(this_controller.functionDefinitionFormSel).show();
		} else {
			$(this_controller.functionDefinitionFormSel).hide();
		}
	},
	
	this.handleUserDefinedFunctionFormSubmit = function(){
		
	},
	
	this.dismiss = function(){
		var selectedFunction = $(this_controller.functionsRadioSel + ":checked").attr("param_value");

		XPLAIN.activeWorkspaceState.currentOperation.mapFunction = selectedFunction;
		
		
		XPLAIN.activeWorkspaceState.currentOperation.relations = this.getSelection();
		XPLAIN.activeWorkspaceState.currentOperation.position = this.getLevel();
		debugger
		if (!this.getSelection().length) {
			XPLAIN.activeWorkspaceState.currentOperation.position -= 1 ;
		}
		
		if(selectedFunction == "user_defined"){
			this_controller.handleUserDefinedFunctionFormSubmit();
		}
	}
	
};

XPLAIN.controllers.MapController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();