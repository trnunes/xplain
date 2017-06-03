
XPAIR.projections = XPAIR.projections || {};


XPAIR.projections.JstreeFacets = function(xset){
	this.xset = xset;
	this.adapter = null;
	this.selectedRelations = [];
	this.$valuesTree = $("#facetModal .facet_values");
	this.$div = $("#facetModal .modal-body");
	var this_projection = this;
	
	
	this.createTree = function($div){
		if ($div.hasClass("jstree")) {
		  $div.jstree("destroy");
		}
	
		$div.jstree({
			"core": {
				"check_callback": true,

			},
			"checkbox" : {
		      "keep_selected_style" : false,
				// three_state : false, // to avoid that fact that checking a node also check others
				whole_node : false,  // to avoid checking the box just clicking the node 
				tie_selection : false, // for checking without selec
				"three_state" : false
			},
			"types" : {
				"Entity" : {
					"icon" : "glyphicon glyphicon-folder-close"
				},
				"SchemaRelation" : {
					"icon" : "glyphicon glyphicon-flash"
				},
				"ComputedRelation" : {
					"icon" : "glyphicon glyphicon-flash"
				},
				"Xpair::Literal": {
					"icon": "glyphicon glyphicon-asterisk"
				}
			},
			"plugins" : [ "sort", "types", "checkbox", "search"],
			"search" : {
				'case_sensitive' : false,
				'show_only_matches' : true
			},
		}).on("check_node.jstree", function(e, data) {
			this_projection.handleRelationSelection(e, data);
		});
		this.registerBehavior();
		$("#facetModal .modal-body").show();
	},
	
	this.init = function(){
		// this.showRelationsTree();
		parameters.put("FacetedRefine", true);
		parameters.put("operation", "refine");
		parameters.put("operator", "=");
		$('#eql_comp').addClass('filter_comparator_active');
		if(!XPAIR.currentOperation){
			XPAIR.currentOperation = new FacetedSearch(new Load(parameters.get('A').attr("id")))
		}
		
		$("#facetModal [aria-label=\"Previous\"]").click(function(e){
			this_projection.previousPage();
		});
		
		$("#facetModal [aria-label=\"Next\"]").click(function(e){
			this_projection.nextPage();
		});
		
		$('#button_add_filter').unbind().click(function(e){
			this_projection.add_filter();
		});
		$("input[param_value='image']").prop("checked", true);

		$("#facetModal").modal("show");
		$("#select_comparator").change(function(){
			this_projection.handleOperatorChanged($(this).val());
			
		});
		this.showImage();
	},
	
	this.handleOperatorChanged = function(operator){
		if(operator == "in"){
			var setData = XPAIR.currentSession.sets.values().map(function(s){ return {id: 'Xset.load("' + s.getId() + '")', text: s.getTitle()}});
			$('.values_select').select2('destroy');
			$('.values_select').empty();
			$('.values_select').select2({
				data: setData,
				placeholder: "Select a Set",
				allowClear: true
			});
		}
		
	},
	
	this.hideRelationsTree = function(){
		$("input[name='radio_pos']").prop('disabled', false);
		$("#facetModal .modal-body").hide();
		var $valuesList = $("#facetModal .facet_values #values_list");
		// $valuesList.empty();
		this.handlePositionChanged();
		this.$div.jstree(true).uncheck_all();
		this.selectedRelations = [];
	},
	this.showRelationsTree = function(){
		// if ($("#facetModal .modal-body").hasClass("jstree")) {
		//   $("#facetModal .modal-body").show();
		//   return
		// }
		$("input[name='radio_pos']").prop('disabled', true);
		this.createTree($("#facetModal .modal-body"));
		
		var set_id = this_projection.xset.getId();
		
		var findRelations = new Flatten(new FindRelations(new Load(set_id), this.getPosition()));
		findRelations.execute("json", function(data){

			var items = data.set.extension;
			var relations_hash = new Hashtable();
			var jstreeAdapter = new XPAIR.adapters.JstreeAdapter(new XPAIR.Xset(data.set));
			this_projection.adapter = jstreeAdapter;
			jstreeAdapter.setProjection(this_projection);
			for(i in items){
				if(items[i].resultedFromArray.length > 1){
					items[i].resultedFrom = items[i].resultedFromArray[items[i].resultedFromArray.length - 2].id
				}
				
				jstreeAdapter.addItem("#", items[i]);
			}
			
			this_projection.$div.show();
		});
		
	},
	
	this.getPosition = function(){
		var position = $("input[name='radio_pos']:checked").attr('param_value');
		return position;
	},
	this.handleRelationSelection = function(e, data){
		debugger;
		e.stopPropagation();
		e.preventDefault();
		
		var facetRelationSelected = data.node;
				
		var checked_nodes = this.$div.jstree().get_checked(true);
		checked_nodes.splice(checked_nodes.indexOf(facetRelationSelected.id));
		this.$div.jstree(true).uncheck_node(checked_nodes);
		
		var $tree = this.$div;
		path = [];


		var parentRelation = $tree.jstree().get_parent(facetRelationSelected);

		pivot = new Pivot(new Flatten(new Load(this.xset.getId())));
		path.push(new Relation(facetRelationSelected.li_attr));
		
		while(parentRelation !== "#") {
			
			facetRelationNode = $tree.jstree().get_node(parentRelation);
			path.unshift(new Relation(facetRelationNode.li_attr));
			parentRelation = $tree.jstree().get_parent(facetRelationNode);
		}
		

		pivot.addRelation(new PathRelation(path));

		var relations_str = path.map(function(r){return r.id}).join("/");
		debugger;
		$('#input_relation').val(relations_str);
		this.selectedRelations = path;
		pivot.execute("json", function(data){
			this_projection.updateValuesList(data.set.extension, data.set.id);
		});
		
		
	},
	
	this.updateValuesList = function(data, setId){
		var items = data;
		$('.values_select').val([]);
		$('.values_select').attr("set", setId);
		$('.values_select').select2({
			ajax: {
				transport: function(params, success, failure){
				  debugger;
				  if(!params.data.term){
					  var load = new Load(setId);
					  load.page = (params.data.page || 1)
					  load.execute("json", function(data){
						  success(data.set.extension);
					  });

					  return;
				  }
				  var r = new Refine(new Load(setId));
				  r.position = this_projection.getPosition();
				  r.page = (params.data.page || 1)
				  r.keywordMatch([[params.data.term]]);
				  var selectData = []
				  r.execute("json", function(data){
					  debugger;
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
				escapeMarkup: function (markup) { return markup; },
				placeholder: "Select a value",
				allowClear: true,
				minimumInputLength: 3,
				cache: false,
  
			}
		});

		for(var i in items){
			debugger;

			$('.values_select').append(new Option(items[i].text, items[i].expression, true, true))
			
			// $valuesList.append("<li><label><input id=\""+items[i].id+"\" datatype=\""+items[i].datatype+"\" item_type=\""+items[i].type+"\" type=\"checkbox\">"+items[i].id+"</label></li>");
			
			// $valuesList.find("[id=\"" + items[i].id + "\"]").click(function(){
			// 	this_projection.handleFacetSelection(this);
			// });
		}

		

	},
		
	this.nextPage = function(){
		var currentPage = parseInt($("#facetModal #current_page").text());
		currentPage++;
		var setId = $("#facetModal .facet_values #values_list").attr("set");
		XPAIR.AjaxHelper.get("/session/render_page.json?set=" + setId + "&page=" + currentPage, "json", function(data){
			$("#facetModal #current_page").html(currentPage);
			this_projection.updateValuesList(data.set.extension, data.set.id);
		});
	},
	
	this.previousPage = function(){
		var currentPage = parseInt($("#facetModal #current_page").text());
		currentPage--;
		var setId = $("#facetModal .facet_values #values_list").attr("set");
		XPAIR.AjaxHelper.get("/session/render_page.json?set=" + setId + "&page=" + currentPage, "json", function(data){
			$("#facetModal #current_page").html(currentPage);
			this_projection.updateValuesList(data.set.extension, data.set.id);
		});
	},
	
	
	this.handleFacetSelection = function(value){
		
		if(value.checked) {

			$('#input_value').val(value.id)
		} 
	},
	
	this.remove_filter = function(){
		XPAIR.currentOperation.removeFacet(this.selectedRelations, parameters.get('operator'), {item_type: $(value).attr("item_type"), datatype: $(value).attr("datatype"), item: value.id});
	},
	this.handlePositionChanged = function(){
		var position = $("input[name='radio_pos']:checked").attr('param_value');
		if(position == "domain"){
			this.showDomain();
		} else {
			this.showImage();
		}
	},
	this.showDomain = function(){
		this.xset.domain(function(data){
			debugger;
			this_projection.updateValuesList(data, this_projection.xset.getId());
		});
	},
	this.showImage = function(){
		this.updateValuesList(this.xset.getImage(), this.xset.getId());
	},
	
	this.add_filter = function(){
		$('#facet_conn').show();
		var position = $("input[name='radio_pos']:checked").attr('param_value');
		var booleanOperator = $("input[name='conn']:checked").attr('param_value');
		var values = $('.values_select').select2('data');
		if(values.length == 0){
			return;
		}
		for(var i in values){
			value = values[i];
			var comparator = $($('#select_comparator').find(":selected")).val();
			debugger;
			var restriction = new Restriction();
			if(this.selectedRelations.length > 0){
				restriction = new RelationRestriction();
			}
			var relation = null;
			if(this.selectedRelations.length > 1){
				relation = new PathRelation(this.selectedRelations);
				restriction.relation = relation;
			} else {
				relation = this.selectedRelations[0];
				restriction.relation = relation;
			}

			restriction.operator = comparator;
			restriction.connector = parameters.get("connector") || "AND";
			restriction.value = new Item({expression: value.id, text: value.text});
		
			restriction.position = position
				
			XPAIR.currentOperation.addRestriction(restriction);
			XPAIR.currentOperation.position = position;
			
		}
		var filter_div = "";
		
		filter_div += XPAIR.currentOperation.toHtml()//.join("<tr class=\"filter_connector\"><td><span>" + XPAIR.currentOperation.connector + "</span></td></tr>");
		$('#facetModal .filters').html("<table>" + filter_div + "</table>");

		$('span .close').click(function(e){
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
				$('#facet_conn').hide();
			}

		});
		
	},
	
	this.show = function(){
		this.registerBehavior();
		$("#facetModal").modal("show");
		parameters.put('relations', []);
	},
	
	
	this.registerBehavior = function(){
		
		this.$div.on("before_open.jstree", function (e, data) {
			e.stopPropagation();
			e.preventDefault();
			var checked_relation = data.node

			for ( var i =0; i < checked_relation.children.length; i++) {
				var child = this_projection.$div.jstree().get_node(checked_relation.children[i])

				if (child.text === "Relations") {
					this_projection.$div.jstree().delete_node(child);
				}		
			}

			if(checked_relation.children.length == 0) {
				debugger;
				var pivot = new Pivot(new Flatten(new Load(checked_relation.li_attr.resultedFrom)));
				pivot.addRelation(new Relation(checked_relation.li_attr));
				pivot.limit = 20

				debugger;

				var findRelations = new FindRelations(pivot);
				
				findRelations.execute("json", function(data){

					var jsTreeAdapter = this_projection.getAdapter();
				
					var relations_hash = new Hashtable();
					var items = data.set.extension;
					for(var i in items){
						if(items[i].resultedFromArray.length > 1){
							items[i].resultedFrom = items[i].resultedFromArray[items[i].resultedFromArray.length - 2].id
						}
							
						jsTreeAdapter.addItem(checked_relation, items[i]);
						
					}
				});
			}
		});		
	}	
},
XPAIR.projections.JstreeFacets.prototype = new XPAIR.projections.AbstractProjection();
