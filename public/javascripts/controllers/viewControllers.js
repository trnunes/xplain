XPLAIN.activeControllers = new Hashtable()
XPLAIN.getController = function(operationName){
	XPLAIN.activeControllers.get(operationName);
};

XPLAIN.controllers = XPLAIN.controllers || {};

XPLAIN.controllers.AbstractRelationsTreeController = function(){};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.init = function(){
	debugger;
	this.setIdOfValuesList = "";
	
	this.treeDivSel = this.viewSelector + " .modal-body";
	this.relatedSetsDiv = this.viewSelector + " .related_sets_div"
	this.relatedSetsSel = this.viewSelector + " .related_sets_select"
	this.relatedSetAct = this.viewSelector + " .related_set_activator"
	this.valuesListSel = this.viewSelector + " .values_select";
	this.positionRadiosSel = this.viewSelector +" input[name='radio_pos']";
	this.positionDivSel = this.viewSelector + " #position";
	this.treeActivatorRadioSel = this.viewSelector + " input[name='radio_strategy']";
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
		if(XPLAIN.currentOperation.execute("json")){
			clear();
			XPLAIN.activeControllers = new Hashtable();
			$(this_controller.viewSelector).parents('.modal').modal('hide');
		}
	});

	$(this.viewSelector +  " #image").prop("checked", true);
	$(".help").empty();
	//TODO correct the level selection
// 	if(this.xset.isMultilevel()){
// 		$(this.positionDivSel).show();
// 	} else {
// 		$(this.positionDivSel).hide();
// 	}
	
	
	if($(this.treeActivatorRadioSel).length){
		// $(this.treeActivatorRadioSel).prop("checked", false);
		// this.handlePositionChanged();
	} else {
		this.loadRelationsTree();
	}
	debugger;
	$(this.viewSelector + " .relation_tree_activator").prop("checked", false)
	$(this_controller.relatedSetsDiv).hide();
	$(this.viewSelector + ' .values_select').val([]);
	$(this.viewSelector + ' .values_select').empty();

	$(this.viewSelector).modal("show");
	this.initController();
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.dismiss = function(){
	if(this.tree){
		debugger;
		this_controller.selectedRelations = this.tree.getSelection();
		this.tree.hide();
	}
	XPLAIN.currentOperation = this.buildOperation();

};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.getSelection = function(){
	if(this.tree){
		return this.tree.getSelection();
	}
	return [];
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.buildOperation = function(){};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.registerBehavior = function(){
	debugger;
	$(this.treeActivatorRadioSel).unbind().change(function() {
		debugger;
		$(this_controller.valuesListSel).select2();
		$(this_controller.valuesListSel).select2('data', null);
		$(this_controller.valuesListSel).empty();
        if(this.checked && $(this).hasClass("relation_tree_activator")) {
			if(this_controller.tree){
				this_controller.tree.restore();
			} else{
				
				this_controller.loadRelationsTree();
			}
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


XPLAIN.controllers.AbstractRelationsTreeController.prototype.handleBranchSelected = function(branch){
	pivot = new Pivot(new Flatten(new Load(this_controller.setId), this_controller.getSelectedPosition(), true), true);
	pivot.addRelation(branch);
	debugger;
	if(this_controller.valuesLimit){
		pivot.limit = this_controller.valuesLimit;
	}
	pivot.execute("json", function(data){
		debugger;
		this_controller.updateValuesList(data.set.extension, data.set.id);
	});
};


XPLAIN.controllers.AbstractRelationsTreeController.prototype.handlePositionChanged = function(){
	debugger;
	if(this.getSelectedPosition() == "domain"){
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
	return $(this.viewSelector + " input[name='radio_pos']:checked").attr('param_value') || "image";
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.handleBranchOpened = function(relation){
	debugger;
	var relation_set_dependencies = relation.li_attr.dependencies
	var set_to_pivot = relation_set_dependencies[relation_set_dependencies.length - 2].id
	var pivot = new Pivot(new Load(set_to_pivot), true);
	pivot.addRelation(new Relation(relation.li_attr));
	pivot.limit = 15;

	var findRelations = new FindRelations(new Flatten(pivot, "image", true), true);

	findRelations.execute("json", function(data){
	
		var relations_hash = new Hashtable();
		var items = data.set.extension;
		for (var i in items){
			this_controller.tree.addItem(relation, items[i]);
		}
	});
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.loadRelationsTree = function(){
	$(this.relatedSetsDiv).hide();
	this.tree = this.tree || new XPLAIN.views.RelationPathTree(this.setId, $(this.treeDivSel), this.treeParams);
	debugger;
	this.tree.createTree($(this.treeDivSel));
	var position = this.getSelectedPosition();
	var findRelations = new Flatten(new FindRelations(new Load(this.setId), position, true), "image", true);
	this.tree.loadData(findRelations);
	debugger;
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
	$(this.viewSelector + ' .values_select').val([]);
	$(this.viewSelector + ' .values_select').empty();
	this.setIdOfValuesList = setId;
	$(this.viewSelector + ' .values_select').select2({
		ajax: {
			transport: function(params, success, failure){
			  if(!params.data.term){
				  var load = new Load(setId);
				  load.page = (params.data.page || 1)
				  load.execute("json", function(data){
					  success(data.set.extension);
				  });

				  return;
			  }
			  var r = new Refine(new Load(setId), true);
			  r.position = this_controller.getSelectedPosition();
			  r.page = (params.data.page || 1);
			  r.keywordMatch([params.data.term]);
			  var selectData = [];
			  r.execute("json", function(data){
				  success(data.set.extension);
			  });
			},
			
			processResults: function(data) {
				var selectData = data.map(function(item){return {id: item.expression, text: item.text}});
				if(selectData.length > 0){
					debugger;
					$(this.viewSelector + ' .values_select').select2('val', selectData[0])
				}
				
				return {
				results: selectData,
					pagination: {
						more: !(selectData.length == 0)
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
	$(".select2-container--default").css("width", '100%');
	for(var i in items){
		$(this.viewSelector + ' .values_select').append(new Option(items[i].text, items[i].expression, true, true));
	}
	if(items.length > 0){
		$(this.viewSelector + ' .values_select').val(items[0].expression);
		$(this.viewSelector + ' .values_select').trigger('change.select2');
	}
	
	
	debugger;
};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.showDomain = function(){
	this.xset.domain(function(data){
		this_controller.updateValuesList(data, this_controller.xset.getId());
	});
};
XPLAIN.controllers.AbstractRelationsTreeController.prototype.showImage = function(){
	this.updateValuesList(XPLAIN.SetController.getExtension(this.setId), this.setId);
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
					data: this_controller.xset.leaves(),
					placeholder: "Select a Set",
					allowClear: true
				});
				
			}	
		});
	},
	
	this.buildOperation = function(){
		var rank = new Rank(new Load(this.setId));
		rank.order = $(this.orderRadiosSel + ":checked").attr("param_value") || "ASC"
		rank.rankFunction = $(this.rankFunctionSel + ":checked").attr("param_value");
		rank.position = this.getSelectedPosition();
		if(this.selectedRelations.length){
			rank.functionParams = {relation: this.selectedRelations[0]}
		}		
		return rank;
	},
	
	this.positionChanged = function(position){
		if(position == "image"){
			$(this_controller.viewSelector + " [param_value=by_image]").parent().hide();
		} else {
			$(this_controller.viewSelector + " [param_value=by_image]").parent().show();
		}
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
		if(!XPLAIN.currentOperation){
			XPLAIN.currentOperation = new FacetedSearch(new Load(this.setId));
		}
		$(this.selectComparatorSel).val("=");

		$(this.connectorsDivSel).hide();
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
		XPLAIN.currentOperation.removeFacet(this.selectedRelations, XPLAIN.activeWorkspaceWidget.params_hash.get('operator'), {item_type: $(value).attr("item_type"), datatype: $(value).attr("datatype"), item: value.id});
	},
	
	this.addFilter = function(){
		$(this.connectorsDivSel).show();
		var position = $(this.positionRadiosSel + ":checked").attr('param_value');
		var booleanOperator = $(this.connectorSel + ":checked").attr('param_value');
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
			restriction.connector = XPLAIN.activeWorkspaceWidget.params_hash.get("connector") || "AND";
			restriction.value = new Item({expression: value.id, text: value.text});
		
			restriction.position = position
				
			XPLAIN.currentOperation.addRestriction(restriction);
			XPLAIN.currentOperation.position = position;
			
		}
		this.updateFiltersTable();
		
	},
	
	this.updateFiltersTable = function(){
		var filter_div = "";
		
		filter_div += XPLAIN.currentOperation.toHtml()//.join("<tr class=\"filter_connector\"><td><span>" + XPLAIN.currentOperation.connector + "</span></td></tr>");
		$(this.filtersDivSel).html("<table>" + filter_div + "</table>");

		$(this.filterCloseSpanSel).click(function(e){
			debugger;
			var facet = $(this).attr("facet");
			var operator = $(this).attr("operator");
			var value = $(this).attr("facet_value");
			if(facet){
				XPLAIN.currentOperation.removeRelationRestriction(facet, operator, value);
			} else{
				XPLAIN.currentOperation.removeSimpleRestriction(operator, value);
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
			if(XPLAIN.currentOperation.isEmpty()){
				$(this.connectorsDivSel).hide();
			}
		});
	},
	
	this.buildOperation = function(){
		return XPLAIN.currentOperation;
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

		if(!XPLAIN.currentOperation){
			XPLAIN.currentOperation = new Pivot(new Load(this.setId));
		}
	},
	
	this.buildOperation = function(){
		debugger;
		XPLAIN.currentOperation.relations = this_controller.selectedRelations;
		return XPLAIN.currentOperation;
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

		if(!XPLAIN.currentOperation){
			XPLAIN.currentOperation = new Group(new Load(this.setId));
		}
		
		$(this.setSel).empty();
		$(this.setSel).select2();
		$(this.restrictGroupsCheckSel).prop("checked", false);
		
		$(this.imageSelectDivSel).hide();
		
		XPLAIN.activeControllers.put('Group', this);
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
		XPLAIN.currentOperation.groupFunction = $operator.attr("param_value");
		
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
		if(XPLAIN.currentOperation.groupFunction == "by_relation"){
			
			var relations = this.selectedRelations
			if(this.selectedRelations.length == 0){
				if($(this.relatedSetsSel).select2('data')[0]){
					relations = [new XsetExpr($(this.relatedSetsSel).select2('data')[0].id)];
				}
			}
				

			XPLAIN.currentOperation.functionParams = {relations: relations};
			debugger;
			if($(this.restrictGroupsCheckSel).prop("checked")){
				var restrictionSet = $(this.setSel).select2('data');
				if(restrictionSet.length){
					XPLAIN.currentOperation.imageSetExpression = restrictionSet[0].id;
				}
				
			}
			
		} else if(XPLAIN.currentOperation.groupFunction == "by_domain"){
			var dependentSet = XPLAIN.SetController.getResultedFrom(this.setId);
		}
		
		return XPLAIN.currentOperation;
	}	
};
XPLAIN.controllers.GroupController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();

XPLAIN.controllers.MapController = function(setId){
	this.setId = setId;
	this.viewSelector = "#mapModal";
	this.functionsRadioSel = this.viewSelector + " input[name='radio_strategy']";
	this.functionDefinitionFormSel = this.viewSelector + " #function_form";
	this_controller = this;

	this.init = function(){
		XPLAIN.currentOperation = new Map(new Load(this.setId));
		$(this.functionDefinitionFormSel).hide();
		

		$(this.functionsRadioSel).unbind().change(function(e){
			debugger;
			this_controller.handleFunctionChange($(this));
		});
		XPLAIN.activeControllers.put('Map', this);
		$(this.viewSelector + " .clear").click(function(){
			clear();
		});
	
		$(this_controller.viewSelector + " .exec").click(function(){
			debugger;
			this_controller.dismiss();
			
			if(XPLAIN.currentOperation.execute("json")){
				clear();
				$(this_controller.viewSelector).parents('.modal').modal('hide');
			}
		});
		
		$(this.viewSelector).modal("show");
		
		
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

		XPLAIN.currentOperation.mapFunction = selectedFunction;
		if(selectedFunction == "user_defined"){
			this_controller.handleUserDefinedFunctionFormSubmit();
		}
	}
	
};

