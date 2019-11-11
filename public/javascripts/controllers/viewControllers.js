XPLAIN.activeControllers = new Hashtable()
XPLAIN.getController = function(operationName){
	XPLAIN.activeControllers.get(operationName);
};

XPLAIN.controllers = XPLAIN.controllers || {};

XPLAIN.controllers.AbstractRelationsTreeController = function(){};

XPLAIN.controllers.AbstractRelationsTreeController.prototype.init = function(){
	
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
	$(this_controller.valuesListSel).parents(' .form-group').hide()
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
	$(this.viewSelector + " #preview").prop("checked", false);
	$(this.viewSelector +" #preview").unbind().change(function(e){
		if ($(this_controller.viewSelector + " #preview").is(":checked")){
			$(this_controller.valuesListSel).parents(' .form-group').show()
			this_controller.handleBranchSelected(this_controller.getSelection()[0]);
		} else {
			$(this_controller.valuesListSel).parents(' .form-group').hide()
		}
		
	});

	$(this.viewSelector +  " #image").prop("checked", true);
	if(this.tree){
		this.tree.destroy();
	}
	$(this.treeDivSel).empty();

	$(".help").empty();
	//TODO correct the level selection
	$(this.positionDivSel + " .radio").remove()
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
	
	
	$(this.positionDivSel + " .radio").remove();
	debugger;
	var radio_html = "<div class=\"radio\"><label><input type=\"radio\" id=\"domain\" name = \"" + this.setId + "_radio\" class = \"param position_radio_input\" param = \"position\" param_value = \"2\"><span>Level 1</span></label></div>"
	$(this.positionDivSel).append(radio_html);
	var lastRadio = $(this.positionDivSel).find('.radio').first().clone();
	for (var i=2; i<=XPLAIN.SetController.countLevels(this.setId); i++)
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
		
			if(this_controller.tree){
				this_controller.loadRelationsTree($(this).attr("param_value"));
			}
			if($(this).is(":checked")){
				debugger
				if(this_controller.getLevel()-1 == XPLAIN.SetController.countLevels(this_controller.setId)){
					$(this_controller.viewSelector + " #by_level").prop("checked", false);
					$(this_controller.viewSelector + " #by_level").parents('.form-group').find('.radio input').first().prop("checked", true);
					$(this_controller.viewSelector + " #by_level").parents('.radio').hide();
				} else {
					$(this_controller.viewSelector + " #by_level").parents('.radio').show();
					$(this_controller.viewSelector + " #by_level").prop("checked", true);
				}
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
	
	if (!pathRelation){ return }

	var relation = pathRelation.relations[pathRelation.relations.length - 1];
	var expression =  "Xplain::ResultSet.load(\""+relation.data.set+"\")";
	expression += ".resulted_from.first";
	var pivot = new Pivot(new Expression(expression));
	pivot.visual = true;
	debugger;
	var path_has_single_relation = pathRelation.relations.length <= 1;
	if (path_has_single_relation){
		pivot.position = this_controller.getLevel();
	}

	pivot.addRelation(relation);
	this_controller.beforePivotBranchSelected(pivot);
	if($(this_controller.viewSelector + " #preview").is(':checked')) {
	//TODO put a limit to the pivot operation
		new Uniq(pivot, true).execute("json", function(data){
			this_controller.updateValuesList(data.extension, data.id);
		});
	}
};


XPLAIN.controllers.AbstractRelationsTreeController.prototype.handlePositionChanged = function(){
	
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
	var expression =  "Xplain::ResultSet.load(\""+relation.data.set+"\")";
	expression += ".resulted_from.first";
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
		levelExpr = "level: "+level;
	}
	var expression = "Xplain::ResultSet.load(\""+this.setId+"\").pivot(limit: 50, visual: true, "+levelExpr+"){ relation \"relations\"}"
	debugger
	this.tree.loadData(expression, false);

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
	
	

	this.setIdOfValuesList = setId;
	that = this;
	$(this.viewSelector + ' .values_select').parent().parent().show();
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
		if (XPLAIN.SetController.countLevels(this.setId) > 1) {
			$(this.viewSelector +  " #domain").first().prop("checked", true);
			$(this.viewSelector + " #by_level").parents(".radio").show();
			$(this.viewSelector + " #by_level").prop("checked", true);
		} else {
			$(this.viewSelector + " #alpha_rank").prop("checked", true);
			$(this.viewSelector + " #by_level").parents('.radio').hide();
		}
		
		$(this.viewSelector + " #asc").prop("checked", true);
		
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
		debugger
		$(this.viewSelector + " #preview").prop("checked", true).parent().parent().hide();

		//$(this.viewSelector + " #preview").parent().parent().hide();
		XPLAIN.activeWorkspaceState.currentOperation = new FacetedSearch(new Load(this.setId));
		
		$(this.selectComparatorSel).val("=");

		$(this.connectorsDivSel).hide();

		$("#cfilter_form").hide();

		$("#define_filter_form").hide();

		$("#cfilter_check").unbind().change(function(e){
			if($("#cfilter_check").is(':checked')) {
				$("#cfilter_form").show();
				$("#define_filter_form").hide();
			} else {
				$("#cfilter_form").hide();
			}
			
		});
		debugger
		$(this.viewSelector + " #relation_radio").change(()=>{
			debugger
			if($(this_controller.viewSelector + " #relation_radio").is(':checked')) {
				$("#define_filter_form").show();
			} else{
				$("#define_filter_form").hide();
			}
		})

		
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
		debugger
		if($("#filter_code_area").val()){
			var filter_code = $("#filter_code_area").val();
			var filter_name = ""
			if ($("#filter_name").val()) {
				filter_name = $("#filter_name").val();
			}
			$("#filter_code_area").val("");
			$("#filter_name").val("");

			XPLAIN.activeWorkspaceState.currentOperation.addFilter(filter_name, filter_code);
		}
		var position = $(this.positionRadiosSel + ":checked").attr('param_value');
		//TODO review the boolean operator
		var booleanOperator = $(this.connectorSel + ":checked").attr('param_value') || "And";
		var values = $(this.valuesListSel).select2('data');
		var selectedRelations = this.getSelection();

		for(var i in values){
			value = values[i];
			var comparator = $($(this.selectComparatorSel).find(":selected")).val();
			
			var valueObj = new Item(value.item_data);

			XPLAIN.activeWorkspaceState.currentOperation.addRestriction(comparator, selectedRelations[0], valueObj);
			
			XPLAIN.activeWorkspaceState.currentOperation.connector = booleanOperator;
			XPLAIN.activeWorkspaceState.currentOperation.position = position;
			
		}
		this.updateFiltersTable();
		
	},
	
	this.updateFiltersTable = function(){
		var that = this;
		var filter_div = "";
		$("#filter_table").remove();

		filter_div += XPLAIN.activeWorkspaceState.currentOperation.toHtml()//.join("<tr class=\"filter_connector\"><td><span>" + XPLAIN.activeWorkspaceState.currentOperation.connector + "</span></td></tr>");
		$(this.filtersDivSel).html("<table id=\"filter_table\">" + filter_div + "</table>");
		debugger

		$(".filter_remove").click(function(e){
			debugger;
			var filter_text = $(this).prev().text();
			XPLAIN.activeWorkspaceState.currentOperation.removeFilter(filter_text);
			that.updateFiltersTable();

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
		XPLAIN.activeWorkspaceState.currentOperation = new Pivot(new Load(this.setId));
		$(this_controller.viewSelector + " #group_by_domain").prop("checked", false);
	},

	this.beforePivotBranchSelected = function(pivot) {
		pivot.limit = 50;
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
		//TODO the params function: by_image is redundant. Correct!
		var params = {function: "by_image", functionParams: this.selectedRelations};
		XPLAIN.activeWorkspaceState.currentOperation.groupFunction = "by_image"
		
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
		pivot.limit = 50;
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
		
		if(selectedFunction == "user_defined"){
			this_controller.handleUserDefinedFunctionFormSubmit();
		}
	}
	
};

XPLAIN.controllers.MapController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();

XPLAIN.controllers.FacetedSearchController = function(setId){
	this.setId = setId;
	this.sourceSet = setId;
	this.viewSelector = "#facetedSearchModal";
	this.filters = [];
	this.filterTexts = [];
	var that = this;

	this.buildFacetsTree = function(){
		$("#facetedSearchModal .facets_area").empty();
		$("#facetedSearchModal .facets_area").jstree("destroy");
		$("#facetedSearchModal .facets_area").jstree({
			"core": {        
				"check_callback": true
			},
			"checkbox" : {
			  "keep_selected_style" : false,
				// three_state : false, // to avoid that fact that checking a node also check others
				whole_node : false,  // to avoid checking the box just clicking the node 
				tie_selection : false // for checking without selec

			},
			"types" : {
			  "Xplain::Entity" : {
				"icon" : "glyphicon glyphicon-folder-close"
			  },
			  "Xplain::Type" : {
				"icon" : "glyphicon glyphicon-folder-close"
			  },
			  "Xplain::SchemaRelation" : {
				"icon" : "glyphicon glyphicon-flash"
			  },
			  "Xplain::ComputedRelation" : {
				"icon" : "glyphicon glyphicon-flash"
			  },
			  "Xplain::Literal": {
				"icon": "glyphicon glyphicon-asterisk"
			  }
			},
			"plugins" : [ "types", "checkbox", "contextmenu", "search", "dnd", "state"],
		});

		

		this.handle_facet_checked = function(e, data) {
			var $tree = $("#facetedSearchModal .facets_area");
			
			//TODO remove duplicated code with uncheck_node

			var item_id = data.node.li_attr.item
			var parent_node = $tree.jstree().get_node($tree.jstree().get_parent(data.node));
			var relation_id = parent_node.li_attr.item;
			var relation_expr = "\"" +  relation_id + "\""
			var inverse = parent_node.li_attr.inverse;
			if (inverse == "true"){
				relation_expr = "inverse(" + relation_expr +")"
			}
			

			var setId = that.setId;
			var item_type = "literal";
			debugger;
			if(data.node.type.toLowerCase() == "xplain::entity" || data.node.type.toLowerCase() == "type"){
				item_type = "entity"
			}
			
			var expression = "equals{ relation " + relation_expr + "%3B "+item_type+" \""+item_id +"\"";
			if(data.node.li_attr.datatype){

				expression += "=> \"" + data.node.li_attr.datatype  + "\""
			}
			expression += "}"
			
			
			that.filters.push(expression);
			that.filterTexts.push(parent_node.text + " = " + data.node.text);
			that.updateFiltersView();
			debugger;

			that.updateFacets("And{[" + that.filters.join(", ") + "]}");
		}
		
		$("#facetedSearchModal .facets_area").on("check_node.jstree", this.handle_facet_checked);
		
		$("#facetedSearchModal .facets_area").on("uncheck_node.jstree", function(e, data) {
			var $tree = $("#facetedSearchModal .facets_area");

			var item_id = data.node.li_attr.item

			var parent_node = $tree.jstree().get_node($tree.jstree().get_parent(data.node));
			var relation_id = parent_node.li_attr.item;
			var inverse = parent_node.li_attr.inverse;
			var setId = that.setId;
			var item_type = "literal";
			//TODO refactor
			debugger
			if(data.node.type == "Xplain::Entity" || data.node.type == "Xplain::Type"){
				item_type = "entity"
			}

			var expression = "equals{ relation \"" + relation_id + "\"%3B "+item_type+" \""+item_id +"\"";
			if(data.node.li_attr.datatype){

				expression += "=> \"" + data.node.li_attr.datatype  + "\""
			}
			expression += "}"
			debugger;
			
			that.removeSelection(expression);
		});

		$("#facetedSearchModal .facets_area").on("before_open.jstree", function (e, data) {
			var $tree = $("#facetedSearchModal .facets_area").jstree(true);
			var children = $tree.get_node(data.node).children
			children.forEach((child)=>{
				$tree.delete_node(child);	
			})
			

			that.load_facet_groups(data.node);
		});

	},
	
	this.removeSelection = function(expression) {
		var index = this.filters.indexOf(expression)
			
		this.filters.splice(index, 1);			
		this.filterTexts.splice(index, 1);
		this.updateFiltersView();
		this.updateFacets("And{[" + that.filters.join(", ") + "]}");
	},

	this.updateFacets = function(filter){
		

		XPLAIN.AjaxHelper.get("/session/apply_facet.json?id="+this.setId+"&filter="+ filter.replace(/#/g, "%23"), "json", function(data){
			debugger;
			that.sourceSet = data.resultedFrom[0].id;
			var $tree = $("#facetedSearchModal .facets_area").jstree(true);
			var nodes = $tree.get_json('#', {flat: true});
			nodes.forEach(function(node){
				$tree.delete_node(node);
			});


			debugger;
			data.extension.forEach((relation)=>{
				var jstreeItem = that.toJstreeNode(relation);
				jstreeItem.children = [{text: "facetgroups"}];
				var nodeId = $tree.create_node('#', jstreeItem, "last", null, false);
			});


			var nodes = $tree.get_json('#', {flat: true});
			nodes.forEach(function(node){
			
			
			that.filters.forEach(function(filter){
				var $jstreeListView = $("#facetedSearchModal .facets_area");
				var splitter = "entity"
				if (node.type == "Xplain::Literal"){
					splitter = "literal";
				}

				if ((filter.split(splitter)[1] + "").indexOf(node.li_attr.item) >= 0 && !node.state.checked && node.text != "facetgroups") {
					$("#facetedSearchModal .facets_area").off("check_node.jstree");
					debugger
					$jstreeListView.jstree(true).check_node(node.id);
					$("#facetedSearchModal .facets_area").on("check_node.jstree", that.handle_facet_checked);
				}

			});

		});
		debugger;	

		});

	},
		
	this.updateFiltersView = function(){
		$('.filters').empty();
		this.filterTexts.forEach(function(filter){
			var filterDiv = $("<div><span class='filterText'>" + filter + "</span><span><a>(X)</a> </span></div>");
			filterDiv.find("a").click(function(){
				that.removeSelection($(this).parents('div').find(".filterText").text());
			});
			
			$('.filters').append(filterDiv);

		});
	},
	this.addFacetRelations = function(){

		XPLAIN.AjaxHelper.get("/session/execute.json?exp=Xplain::ResultSet.load(\""+ this.setId + "\").pivot(visual: true){relation \"relations\"}", "json", function(data){

			var $jstreeListView	= $("#facetedSearchModal .facets_area");
			debugger;
			data.extension.forEach((relation)=>{
				var jstreeItem = that.toJstreeNode(relation);
				jstreeItem.children = [{text: "facetgroups"}];
				var nodeId = $jstreeListView.jstree(true).create_node('#', jstreeItem, "last", null, false);
			});
			
		});

	},

	this.addFacetGroup = function(facetJson){
		var $jstreeListView	= $("#facetedSearchModal .facets_area");
		var jstreeItem = this.toJstreeNode(facetJson.facet_group);
		var isFilter = false;
		jstreeItem.children = []
		jstreeItem.children = facetJson.facets.map((facet)=>{
			var jstreefacetJson = this.toJstreeNode(facet);
			jstreefacetJson.text += " ("+ facet.size +") ";
			
			return jstreefacetJson;
		});
		
		
		var nodeId = $jstreeListView.jstree(true).create_node('#', jstreeItem, "last", null, false);
				
		return nodeId;
	},

	this.toJstreeNode = function(item){
		var parsed_item = {
			text: item.text,
			type: item.type,
			item_data: {
				item: item.id,
			},
			li_attr: {
				item: item.id,
			}
		}

		if (item.type == "Xplain::Literal"){
			parsed_item.li_attr['datatype'] = item.datatype
			parsed_item.li_attr.item = item.text
		} else if (item.type == "Xplain::SchemaRelation") {
			parsed_item.item_data['inverse'] =  item.inverse
			parsed_item.li_attr['inverse'] =  item.inverse
		}
		return parsed_item;
	},
	
	this.initController = function(){
		this.buildFacetsTree();
		//var parse_facet_groups = (facet_groups) => {
		//	facet_groups.forEach((fgroup) =>{
		//		this.addFacetGroup(fgroup);
		//	});
		//}
		//this.load_facets(parse_facet_groups)
		this.addFacetRelations();
	},

	this.load_facet_groups = function(relation){
		var relation_id = relation.li_attr.item
		var is_inverse_param = ""
		if (relation.li_attr.inverse){
			is_inverse_param = "&inverse=" + relation.li_attr.inverse	
		}

		XPLAIN.AjaxHelper.get("/session/render_faceted_search.json?id="+ this.sourceSet + "&relation=" + relation_id.replace(/#/, "%23") + is_inverse_param, "json", function(data){
			debugger;
			var $jstreeListView	= $("#facetedSearchModal .facets_area");
				
			data.facets.forEach((facet)=>{
				debugger
				var jstreefacetJson = that.toJstreeNode(facet);
				jstreefacetJson.text += " ("+ facet.size +") ";
				$jstreeListView.jstree(true).create_node(relation.id, jstreefacetJson, "last", null, false);
			});

			//TODO replicated with updateFacets
			var nodes = $("#facetedSearchModal .facets_area").jstree(true).get_json('#', {flat: true});
			nodes.forEach(function(node){
			
			
				that.filters.forEach(function(filter){
					var $jstreeListView = $("#facetedSearchModal .facets_area");
					var splitter = "entity"
					if (node.type == "Xplain::Literal"){
						splitter = "literal";
					}

					if ((filter.split(splitter)[1] + "").indexOf(node.li_attr.item) >= 0 && !node.state.checked && node.text != "facetgroups") {
						$("#facetedSearchModal .facets_area").off("check_node.jstree");
						debugger
						$jstreeListView.jstree(true).check_node(node.id);
						$("#facetedSearchModal .facets_area").on("check_node.jstree", that.handle_facet_checked);
					}

				});


			});
			
		});
	},

	this.load_facets = function(callback){
		XPLAIN.AjaxHelper.get("/session/render_faceted_search.json?id="+ this.setId, "json", function(data){
			debugger;
			callback(data);
		});
	},

	this.dismiss = function(){
		
		var filter_expression = "And{[";
		debugger
		this.filters.forEach((filter)=>{
			filter_expression += filter + ", "

		})
		filter_expression += "]}"

		var expression = "Xplain::ResultSet.load(\""+this.setId+"\").refine{ "+filter_expression+"}"
		XPLAIN.AjaxHelper.get("/session/execute.json?exp="+ expression.replace(/#/g, "%23"), "json", function(data){
			
			debugger
			XPLAIN.activeWorkspaceState.addSetFromJson(data);
		});


	}

}

XPLAIN.controllers.FacetedSearchController.prototype = new XPLAIN.controllers.AbstractRelationsTreeController();