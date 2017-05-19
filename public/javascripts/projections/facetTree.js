
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
				"Relation" : {
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
	},
	
	this.init = function(){
		this.createTree($("#facetModal .modal-body"));
		
		var set_id = this_projection.xset.getId();
		var findRelations = new FindRelations(new Load(set_id));
		findRelations.execute("json", function(data){

			var items = data.set.extension;
			var relations_hash = new Hashtable();
			var jstreeAdapter = new XPAIR.adapters.JstreeAdapter(new XPAIR.Xset(data.set));
			this_projection.adapter = jstreeAdapter;
			jstreeAdapter.setProjection(this_projection);
			for(i in items){
				jstreeAdapter.addItem("#", items[i]);
			}
			
			this_projection.show();
		});
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
		// this.$div.jstree(true).disable_checkbox(facetRelationSelected);
		// $tree.jstree(true).check_node(facetRelationSelected);
		// this.$div.jstree(true).enable_checkbox(facetRelationSelected);

		pivot = new Pivot(new Load(this.xset.getId()));
		path.push(facetRelationSelected.li_attr);
		
		while(parentRelation !== "#") {
			
			facetRelationNode = $tree.jstree().get_node(parentRelation);
			path.unshift(facetRelationNode.li_attr);
			parentRelation = $tree.jstree().get_parent(facetRelationNode);
		}
		
		if(path.length > 1){
			pivot.isPath = true;
		}
		for(var i in path){
			pivot.addRelation(path[i]);
		}
		this.selectedRelations = path;
		pivot.execute("json", function(data){
			this_projection.updateValuesList(data);
		});
		
	},
	
	this.updateValuesList = function(data){
		var items = data.set.extension;
		var $valuesList = $("#facetModal .facet_values #values_list");
		$valuesList.empty();
		$valuesList.attr("set", data.set.id)
		for(var i in items){
			debugger;
			
			
			$valuesList.append("<li><label><input id=\""+items[i].id+"\" datatype=\""+items[i].datatype+"\" item_type=\""+items[i].type+"\" type=\"checkbox\">"+items[i].id+"</label></li>");
			
			$valuesList.find("[id=\"" + items[i].id + "\"]").click(function(){
				this_projection.handleFacetSelection(this);
			});
		}
		

	},
	
	this.nextPage = function(){
		var currentPage = parseInt($("#facetModal #current_page").text());
		currentPage++;
		var setId = $("#facetModal .facet_values #values_list").attr("set");
		XPAIR.AjaxHelper.get("/session/render_page.json?set=" + setId + "&page=" + currentPage, "json", function(data){
			$("#facetModal #current_page").html(currentPage);
			this_projection.updateValuesList(data);
		});
	},
	
	this.previousPage = function(){
		var currentPage = parseInt($("#facetModal #current_page").text());
		currentPage--;
		var setId = $("#facetModal .facet_values #values_list").attr("set");
		XPAIR.AjaxHelper.get("/session/render_page.json?set=" + setId + "&page=" + currentPage, "json", function(data){
			$("#facetModal #current_page").html(currentPage);
			this_projection.updateValuesList(data);
		});
	},
	
	
	this.handleFacetSelection = function(value){
		debugger;
		if(value.checked) {
			XPAIR.currentOperation.addFacet(this.selectedRelations, parameters.get('operator'), {item_type: $(value).attr("item_type"), datatype: $(value).attr("datatype"), item: value.id}, parameters.get('connector'));
		} else {
			XPAIR.currentOperation.removeFacet(this.selectedRelations, parameters.get('operator'), {item_type: $(value).attr("item_type"), datatype: $(value).attr("datatype"), item: value.id});
		}
		var filter_div = "";
		filter_div += XPAIR.currentOperation.toHtml().join("<tr class=\"filter_connector\"><td><span>" + XPAIR.currentOperation.connector + "</span></td></tr>");
		$('#facetModal .modal-header .filters').html("<table>" + filter_div + "</table>");
		
		$('span .close').click(function(e){
			debugger;
			var facet = $(this).attr("facet")
			var path = facet.split(" → ").map(function(relationID){ return {item: relationID.trim()}});
			var value = {item: $(this).attr("facet_value")}
			XPAIR.currentOperation.removeFacet(path, "", value);
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
				
				var pivot = new Pivot(new Load(checked_relation.data.resultedFrom));
				pivot.addRelation(checked_relation.data);
				pivot.limit = 20

				debugger;

				var findRelations = new FindRelations(pivot);
				
				findRelations.execute("json", function(data){

					var jsTreeAdapter = this_projection.getAdapter();
				
					var relations_hash = new Hashtable();
					var items = data.set.extension;
					for(var i in items){
						jsTreeAdapter.addItem(checked_relation, items[i]);
					}
				});
			}
		});		
	}	
},
XPAIR.projections.JstreeFacets.prototype = new XPAIR.projections.AbstractProjection();
