XPAIR.controllers = XPAIR.controllers || {};

XPAIR.controllers.AbstractRelationsTreeController = function(){};

XPAIR.controllers.AbstractRelationsTreeController.prototype.init = function(){
	debugger;
	this.setIdOfValuesList = "";
	
	this.treeDivSel = this.viewSelector + " .modal-body";
	this.valuesListSel = this.viewSelector + " .values_select";
	this.positionRadiosSel = this.viewSelector +" input[name='radio_pos']";
	this.positionDivSel = this.viewSelector + " #position";
	this.treeActivatorRadioSel = this.viewSelector + " input[name='radio_strategy']";
	this.selectedRelations = [];
	this.treeParams = {allowMultipleSelection: false};
	
	this.registerBehavior();
	this_controller = this;

	$(this.viewSelector).off('hide.bs.modal').on("hide.bs.modal", function(){
		this_controller.dismiss();
	});

	$(this.viewSelector +  " #image").prop("checked", true);
	if(this.xset.isGroupedSet()){
		$(this.positionDivSel).show();
	} else {
		$(this.positionDivSel).hide();
	}
	if($(this.treeActivatorRadioSel).length){
		$(this.treeActivatorRadioSel).prop("checked", false);
		this.handlePositionChanged();
	} else {
		this.loadRelationsTree();
	}

	$(this.viewSelector).modal("show");
	this.initController();
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.dismiss = function(){
	if(this.tree){
		debugger;
		this_controller.selectedRelations = this.tree.getSelection();
		this.tree.hide();
	}
	XPAIR.currentOperation = this.buildOperation();

};

XPAIR.controllers.AbstractRelationsTreeController.prototype.getSelection = function(){
	if(this.tree){
		return this.tree.getSelection();
	}
	return [];
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.buildOperation = function(){};

XPAIR.controllers.AbstractRelationsTreeController.prototype.registerBehavior = function(){
	debugger;
	$(this.treeActivatorRadioSel).unbind().change(function() {
		debugger;
        if(this.checked && $(this).hasClass("relation_tree_activator")) {
			if(this_controller.tree){
				this_controller.tree.restore();
			} else{
				this_controller.loadRelationsTree();
			}
        } else {
			if(this_controller.tree){
				this_controller.tree.hide();
				this_controller.handlePositionChanged();
			}
        }
    });
	
	$(this.positionRadiosSel).unbind().change(function(){
		this_controller.handlePositionChanged();
	});
	
	this.registerControllerBehavior();
};


XPAIR.controllers.AbstractRelationsTreeController.prototype.handleBranchSelected = function(branch){
	pivot = new Pivot(new Flatten(new Load(this_controller.xset.getId()), this_controller.getSelectedPosition()));
	pivot.addRelation(branch);
	debugger;
	if(this_controller.valuesLimit){
		pivot.limit = this_controller.valuesLimit;
	}
	pivot.execute("json", function(data){
		this_controller.updateValuesList(data.set.extension, data.set.id);
	});
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.handlePositionChanged = function(){
	if(this.getSelectedPosition() == "domain"){
		this.showDomain();
	} else {
		this.showImage();
	}
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.getSelectedPosition = function(){
	return $(this.viewSelector + " input[name='radio_pos']:checked").attr('param_value') || "image";
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.handleBranchOpened = function(relation){
	var pivot = new Pivot(new Flatten(new Load(relation.li_attr.resultedFrom)));
	pivot.addRelation(new Relation(relation.li_attr));
	pivot.limit = 15;

	var findRelations = new FindRelations(pivot);
	
	findRelations.execute("json", function(data){

		var jsTreeAdapter = this_controller.tree.adapter
	
		var relations_hash = new Hashtable();
		var items = data.set.extension;
		for(var i in items){
			if(items[i].resultedFromArray.length > 1){
				items[i].resultedFrom = items[i].resultedFromArray[items[i].resultedFromArray.length - 2].id
			}	
			jsTreeAdapter.addItem(relation, items[i]);
		}
	});
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.loadRelationsTree = function(){
	this.tree = this.tree || new XPAIR.projections.RelationPathTree(this.xset, $(this.treeDivSel), this.treeParams);
	debugger;
	this.tree.createTree($(this.treeDivSel));
	var position = this.getSelectedPosition();
	var findRelations = new Flatten(new FindRelations(new Load(this.xset.getId()), position));
	this.tree.loadData(findRelations);
	debugger;
	this.tree.onBranchSelected(this.handleBranchSelected);
	this.tree.onBranchOpened(this.handleBranchOpened);
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.updateValuesList = function(data, setId){
	var items = data;
	$(this.viewSelector + ' .values_select').val([]);
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
			  var r = new Refine(new Load(setId));
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
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.showDomain = function(){
	this.xset.domain(function(data){
		this_controller.updateValuesList(data, this_controller.xset.getId());
	});
};
XPAIR.controllers.AbstractRelationsTreeController.prototype.showImage = function(){
	this.updateValuesList(this.xset.getImage(), this.xset.getId());
};

XPAIR.controllers.AbstractRelationsTreeController.prototype.initController = function(){};
XPAIR.controllers.AbstractRelationsTreeController.prototype.registerControllerBehavior = function(){};
XPAIR.controllers.AbstractRelationsTreeController.prototype.handleValueSelection = function(value){};


XPAIR.controllers.RankController = function(xset){
	this.xset = xset;
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
		$(this.viewSelector +  " #image").prop("checked", true);
	},
	
	
	this.buildOperation = function(){
		var rank = new Rank(new Load(this.xset.getId()));
		rank.order = $(this.orderRadiosSel + ":checked").attr("param_value") || "ASC"
		rank.rankFunction = $(this.rankFunctionSel + ":checked").attr("param_value");
		rank.position = this.getSelectedPosition();
		if(this.selectedRelations.length){
			rank.functionParams = {relation: this.selectedRelations[0]}
		}		
		return rank;
	}
	
};

XPAIR.controllers.RankController.prototype = new XPAIR.controllers.AbstractRelationsTreeController();

XPAIR.controllers.RefineController = function(xset){
	this.xset = xset;
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
		parameters.put("FacetedRefine", true);
		parameters.put("operation", "refine");
		parameters.put("operator", "=");
		$('#eql_comp').addClass('filter_comparator_active');
		if(!XPAIR.currentOperation){
			XPAIR.currentOperation = new FacetedSearch(new Load(this.xset.getId()));
		}

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
			var setData = XPAIR.currentSession.sets.values().map(function(s){ return {id: 'Xset.load("' + s.getId() + '")', text: s.getTitle()}});
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
		XPAIR.currentOperation.removeFacet(this.selectedRelations, parameters.get('operator'), {item_type: $(value).attr("item_type"), datatype: $(value).attr("datatype"), item: value.id});
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
			restriction.connector = parameters.get("connector") || "AND";
			restriction.value = new Item({expression: value.id, text: value.text});
		
			restriction.position = position
				
			XPAIR.currentOperation.addRestriction(restriction);
			XPAIR.currentOperation.position = position;
			
		}
		this.updateFiltersTable();
		
	},
	
	this.updateFiltersTable = function(){
		var filter_div = "";
		
		filter_div += XPAIR.currentOperation.toHtml()//.join("<tr class=\"filter_connector\"><td><span>" + XPAIR.currentOperation.connector + "</span></td></tr>");
		$(this.filtersDivSel).html("<table>" + filter_div + "</table>");

		$(this.filterCloseSpanSel).click(function(e){
			debugger;
			var facet = $(this).attr("facet");
			var operator = $(this).attr("operator");
			var value = $(this).attr("facet_value");
			if(facet){
				XPAIR.currentOperation.removeRelationRestriction(facet, operator, value);
			} else{
				XPAIR.currentOperation.removeSimpleRestriction(operator, value);
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
			if(XPAIR.currentOperation.isEmpty()){
				$(this.connectorsDivSel).hide();
			}
		});
	},
	
	this.buildOperation = function(){
		return XPAIR.currentOperation;
	}	
};
XPAIR.controllers.RefineController.prototype = new XPAIR.controllers.AbstractRelationsTreeController();

XPAIR.controllers.PivotController = function(xset){
	this.xset = xset;
	this.viewSelector = "#pathModal";
	this.valuesLimit = 10;
	var this_controller = this;
	
	this.initController = function(){
		this.treeParams.allowMultipleSelection = true;

		if(!XPAIR.currentOperation){
			XPAIR.currentOperation = new Pivot(new Load(this.xset.getId()));
		}
	},
	
	this.buildOperation = function(){
		debugger;
		XPAIR.currentOperation.relations = this.selectedRelations;
		return XPAIR.currentOperation;
	}	
};
XPAIR.controllers.PivotController.prototype = new XPAIR.controllers.AbstractRelationsTreeController();

XPAIR.controllers.GroupController = function(xset){
	this.xset = xset;
	this.viewSelector = "#groupModal";
	var this_controller = this;
	this.operatorSel = this.viewSelector + " input[name='radio_strategy']";
	this.valuesLimit = 10;
	
	this.initController = function(){
		this.treeParams.allowMultipleSelection = true;

		if(!XPAIR.currentOperation){
			XPAIR.currentOperation = new Group(new Load(this.xset.getId()));
		}
		
	},
	
	this.registerControllerBehavior = function(){
		$(this.operatorSel).change(function(){
			this_controller.handleOperatorChanged($(this));
		});
	},
	
	this.handleOperatorChanged = function($operator){
		XPAIR.currentOperation.groupFunction = $operator.attr("param_value");
	},
	
	this.buildOperation = function(){
		if(XPAIR.currentOperation.groupFunction == "by_relation"){
			debugger;
			XPAIR.currentOperation.functionParams = {relations: this.selectedRelations};
		}
		
		return XPAIR.currentOperation;
	}	
};
XPAIR.controllers.GroupController.prototype = new XPAIR.controllers.AbstractRelationsTreeController();

XPAIR.controllers.MapController = function(xset){
	this.xset = xset;
	this.viewSelector = "#mapModal";
	this.functionsRadioSel = this.viewSelector + " input[name='radio_strategy']";
	this.functionDefinitionFormSel = this.viewSelector + " #function_form";
	this_controller = this;

	this.init = function(){
		XPAIR.currentOperation = new Map(new Load(this.xset.getId()));
		$(this.functionDefinitionFormSel).hide();
		
		$(this.viewSelector).on("hide.bs.modal", function(){
			this_controller.dismiss();
		});
		$(this.functionsRadioSel).unbind().change(function(e){
			this_controller.handleFunctionChange($(this));
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
		var selectedFunction = $(this.functionsRadioSel + ":checked").attr("param_value");
		XPAIR.currentOperation.mapFunction = selectedFunction;
		if(selectedFunction == "user_defined"){
			this.handleUserDefinedFunctionFormSubmit();
		}
	}
	
};

