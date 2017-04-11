XPAIR.projections = XPAIR.projections || {};

XPAIR.projections.AbstractProjection = function(){
	this.adapter = null;
},
XPAIR.projections.AbstractProjection.prototype.getAdapter = function(){
	return this.adapter;
},
XPAIR.projections.AbstractProjection.prototype.getXset = function(){
	return this.xset;
},

XPAIR.projections.AbstractProjection.prototype.getDiv = function(){
	return this.$div;
},
XPAIR.projections.AbstractProjection.prototype.init = function(){
	return;
},
XPAIR.projections.AbstractProjection.prototype.registerBehavior = function(){
	return;
},
XPAIR.projections.AbstractProjection.prototype.show = function(){
	return;
},


XPAIR.projections.JstreePath = function(adapter){
	this.adapter = adapter;
	this.adapter.setProjection(this);
	this.path = [];

	this.$div = null;
	var this_projection = this;
	this.init = function(){
		if ($("#myModal .modal-body").hasClass("jstree")) {
		  $("#myModal .modal-body").jstree("destroy");
		}
		
		$(".modal-body").jstree({
			"core": {
				"check_callback": true,
				"data": adapter.convertFormat()

			},
			"checkbox" : {
				"keep_selected_style" : false,
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
		});
		this_projection.$div = $(".modal-body");

	},
	
	this.show = function(){
		this.init();
		this.registerBehavior();
		$("#myModal").modal("show");
	},
	
	
	this.registerBehavior = function(){
		this.$div.on("activate_node.jstree", function(e, data){			
			var relation = data.node;			
			var relations = [];
			var parent_relation = this_projection.$div.jstree().get_parent(relation);

			if(this_projection.$div.jstree().is_checked(relation)) {
				if(this_projection.path.indexOf(relation.id) < 0){
					this_projection.path.unshift(relation.id);
					while(parent_relation !== "#") {
						this_projection.$div.jstree().check_node(parent_relation);
						var parent_relation_node = this_projection.$div.jstree().get_node(parent_relation)
						this_projection.path.unshift(parent_relation_node.id);
						parent_relation = this_projection.$div.jstree().get_parent(parent_relation);
					}
					var parent_relation = this_projection.$div.jstree().get_parent(relation);
					var is_child = !(parent_relation === "#");
					if(is_child){
						this_projection.isPath = true;
					}else{
						this_projection.isPath = false;
					}				
				}
			} else {
				if(this_projection.path.indexOf(relation.id) >= 0){
					this_projection.path.splice(this_projection.path.indexOf(relation.id));
				}				
			}
			
			parameters.put("B", []);
			parameters.put("isPath", this_projection.isPath)

			for(var i in this_projection.path){
				parameters.get("B").push($("#"+this_projection.path[i]));
			}			
		});
		
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
				pivot.addRelation(checked_relation.data.item);				
				var findRelations = new FindRelations(pivot);
				
				findRelations.execute("json", function(data){

					var jsTreeAdapter = this_projection.getAdapter();
				
					var relations_hash = new Hashtable();
					var items = data.set.extension;
					for(var i in items){
						var item = items[i];
						for(j in item.relations){
							var relation = item.relations[j];
							relation.values = [];
							if (!relations_hash.containsKey(relation.id)){
								relations_hash.put(relation.id, relation);
							}
						}
					}
					var relations = relations_hash.values();
					for(var i in relations){
						jsTreeAdapter.addItem(checked_relation, relations[i]);
					}
				});
			}
		});		
	}	
},
XPAIR.projections.JstreePath.prototype = new XPAIR.projections.AbstractProjection();

XPAIR.projections.Jstree = function(adapter){
	this.xset = adapter.getXset();
	this.adapter = adapter;
	this.adapter.setProjection(this);
	XPAIR.currentSession.addProjection(this.xset.getId(), this);
	var this_projection = this;
	
	this.getDiv = function(){
		return this.xset.getItemsArea();
	},
		
	this.init = function(){
		var view = this.xset.getView()
		var $div = this.xset.getItemsArea();
		if ($div.hasClass("jstree")){
			return;
		}
		$div.jstree({
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
		      "Entity" : {
		        "icon" : "glyphicon glyphicon-folder-close"
		      },
		      "Type" : {
		        "icon" : "glyphicon glyphicon-folder-close"
		      },
		      "Relation" : {
		        "icon" : "glyphicon glyphicon-flash"
		      },
			  "Xpair::Literal": {
				  "icon": "glyphicon glyphicon-asterisk"
			  }
	  
		    },
		    "plugins" : [ "types", "checkbox", "contextmenu", "search", "dnd", "state"],
		    "search" : {
		                 'case_sensitive' : false,
		                 'show_only_matches' : true
		            },
			"contextmenu": this.createTreeContextMenu($div)
		}).on("check_node.jstree uncheck_node.jstree", function(e, data) {
			
			this_projection.handleFacetSelection(e, data);
		})
		
	    var to = false;
	    $('.search-input').keyup(function () {
	      if(to) { 
			  clearTimeout(to); 
		  }
	      to = setTimeout(function () {
	        var v = $('.search-input').val();
	        $div.jstree(true).search(v);
	      }, 250);
	    });
		this.adapter.populate();
		$div.jstree().hide_checkboxes();	
		this.registerBehavior();
		this.registerMoveNodeBehavior();
		XPAIR.graph.addXset(this.xset);
		
	},
	
	this.registerMoveNodeBehavior = function(){
		var $div = this.xset.getItemsArea();
		$div.on("copy_node.jstree", function (e, data) {
			
			var setId = this_projection.xset.getId();
			target_node_id = data.node.li_attr.item;
			target_node_set = data.node.li_attr.set
			union = new Union([new Load(setId), new Select(new Load(target_node_set), [target_node_id])]);
			union.execute("json", function(data){console.log(data)});
			
		});

		
	},
	
	this.registerBehavior = function(){
		var $setView = this.xset.getView();
		var $div = this.xset.getItemsArea();
		this.createPivotMenu($setView);
		this.createProjectionMenu($setView);
		this.registerTreeSelectionBehavior($div);
		this.registerItemBehavior($div);
		// this.registerFilteringBehavior();
	},
	this.activateFacetedFiltering = function(){
		
		// if(this.xset.getGenerates().length == 0){
		// 	alert("You must generate at least one set from the current in order to facet.");
		// 	return
		// }

		for ( var i in this.xset.getGenerates()){
			var xset = this.xset.getGenerates()[i];
			var projections = XPAIR.currentSession.getProjections(xset.getId());
			for(var j in projections){
				if(projections[j].getDiv().is(':visible')){
					projections[j].getDiv().jstree().uncheck_all();
					projections[j].getDiv().jstree().show_checkboxes();
				}
				
				projections[j].activateFacetedFiltering();
				
			
			
			}
		
		}
		parameters.put("FacetedRefine", true);
		parameters.put("operation", "refine");
		if(!XPAIR.currentOperation){
			XPAIR.currentOperation = new FacetedSearch(new Load(parameters.get('A').attr("id")))
		}
			

				
		
	},
	
	this.handleFacetSelection = function(e, data){
		var $tree = this.getDiv();
		if(!parameters.get("FacetedRefine")){
			return;
		}
		


		

		var filterExpr;		
		var facetValueNode = data.node;
		
		var facetRelationId = $tree.jstree().get_parent(facetValueNode);
		var facetRelationNode = $tree.jstree().get_node(facetRelationId);
		
		var currentSetId = this_projection.xset.getId();
		debugger;

			var path = []
			var facet = null;
			var value = null;
			
			facet = facetRelationNode.li_attr	
			
			var setToFilterId = parameters.get('A').attr("id");
			
			var facetDomainItem = $tree.jstree().get_node($tree.jstree().get_parent(facetRelationId));
			var parentNode = $tree.jstree().get_node($tree.jstree().get_parent(facetDomainItem));
			
			var filterByRelationSet = (currentSetId != setToFilterId)			
			var relationOperation = null;
			
			if(filterByRelationSet){
				relationOperation = new Load(currentSetId);
				facet = relationOperation;				
			}
			value = facetValueNode.li_attr;
			
			if(parentNode && (parentNode.id != "#")){
				
				if(relationOperation){
					relationOperation = new Pivot(relationOperation);
				} else {
					relationOperation = new Pivot(new Load(setToFilterId));
				}
				
				path.unshift(facetRelationNode);

				while(parentNode !== "#") {
					
					facetRelationNode = $tree.jstree().get_node(parentNode);
					facetDomainItem = $tree.jstree().get_node($tree.jstree().get_parent(facetRelationNode.id));
					path.unshift(facetRelationNode);
					var parentNode = $tree.jstree().get_parent(facetDomainItem);
					$tree.jstree().check_node(parentNode.id);
				
				}
				console.log("Path: ", path);
				for(var i in path){
					relationOperation.appendToPath(path[i].li_attr.item);
				}
				// refine = new Refine(new Load(setToFilterId));
				// refine.equals([operation], [facetValueNode.li_attr]);

					// XPAIR.currentOperation.addFacet(relationOperation, facetValueNode.li_attr)
				facet = relationOperation
				value = facetValueNode.li_attr
				console.log("Faceted", XPAIR.currentOperation);
				console.log("EXPRESSION", XPAIR.currentOperation.getExpression());
				
			}
			
			if($tree.jstree().is_checked(facetValueNode)) {
				
				XPAIR.currentOperation.addFacet(facet, value, parameters.get('connector'));
			} else {
				XPAIR.currentOperation.removeFacet(facet, value);
			}

		
	
		
	},
	this.show = function(){
		this.init();
		this.xset.getView().show();
	},
	
	this.clear = function(){

		if (typeof this.getDiv().jstree().uncheck_all !== "undefined") { 
			this.getDiv().jstree().uncheck_all();
			this.getDiv().jstree().hide_checkboxes();		    
		}

	},
	this.createPivotMenu = function($setView){
		var set_id = $setView.attr("id");
		console.log("#" + set_id + " .pivot_button");
	    $(function() {
			var isForward = true;
			var isPath = false;
			var isMultiple = false;		
			$.contextMenu({
			  selector: "#" + set_id + " .pivot_button",
			  trigger: 'left',
			  callback: function(key, options) {
			      var m = "clicked: " + key;
			      window.console && console.log(m) || alert(m); 
			  },
			  items: {
			      "forward": {name: "Forward", selected: true, type: "radio"},
			      "backward": {name: "Backward", type: "radio", events: {change: function(e){isForward = false}}},                 
			      "sep1": "---------",
				  "ismultiple": {name: "Multiple", type: "checkbox", events: {change: function(e){isMultiple = true}}},
				  "ispath": {name: "Path", type: "checkbox", events: {change: function(e){isPath = true}}},
				  "path": {
					  name: "Select Relations",
					  callback: this_projection.showPathModal()
				  },
				  
				  "sep2": "---------",
				  key: {
					name: "Pivot", 
					callback: function(){
						var pivot = new Pivot(new Load(set_id));
						if(!isForward) {
							pivot.backward(true);
						}
						
						$(".SELECTED").each(function(){
							var selectedRelation = this_projection.xset.getItemsArea().jstree().get_node($(this).attr("id"))

							if (isPath) {
								pivot.appendToPath(selectedRelation.data.item);
							} else {
								pivot.addRelation(selectedRelation.data.item);
							}							
						});
					
						pivot.execute("json")
					
						isForward = true;
						isPath = false;
						isMultiplec = false;
					}
			      },
			      "quit": {name: "Quit", icon: function(){
			          return 'context-menu-icon context-menu-icon-quit';
			      }}
			  },

			});

			$("#" + set_id + " .pivot_button").on('click', function(e){
			  console.log('clicked', this);
			})    
		});
		
	},
		
	this.createProjectionMenu = function($setView){
		
		$setView.find(".project_button").click(function(){
			var set_id = $setView.attr("id");
			var get_relations_url = '/session/common_relations?set='+ set_id;
			if (!context_menus_hash.containsKey(set_id)) {
				var context_menu_generation = function() {
						$.contextMenu({
						    selector: "#" + set_id + " .project_button",
							trigger: 'left',
						    build: function($triggerElement, e){
						        return {
									items:{
									    select: {
									        name: "Select a relation", type: 'select', options: common_relations_menu,
									        events: {
									            change: function (e) {
													var selectedRelation = $(e.target).find(":selected").text();
													project(set_id, selectedRelation);
									            }
									        }
										}
									}
								};
							}
						});
						context_menus_hash.put(set_id, true);
						$("#" + set_id + " .project_button").trigger("click");

					}
				ajax_get(get_relations_url, context_menu_generation);			
			}
		});		
	},
	
	this.createTreeContextMenu = function($treeView){
		
		return {         
		    "items": function($node) {
			
		        var tree = $treeView.jstree(true);
				var node = $treeView.jstree().get_node($node.id);
				var common_menu_options = {}
				common_menu_options = {
					"label": "Trace Path",
					"action": function(obj){
						$(".SELECTED").each(function(){
							if(this_projection.xset.getResultedFrom()){
								console.log("tracing ", this);
								this_projection.adapter.trace($(this));
							}
							
						});
					}
				};
				if (node.type === "Entity"){
			        return {
						"Trace": common_menu_options,

			            "Select": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Select",
			                "action": function (obj) { 
								var unionsHash = new Hashtable();
								$(".SELECTED").each(function(){
									
									var selected_node = $treeView.jstree().get_node($(this).attr("id"));
									if(!unionsHash.containsKey(selected_node.li_attr.set)){
										unionsHash.put(selected_node.li_attr.set, []);
									}
									unionsHash.get(selected_node.li_attr.set).push(selected_node.li_attr.item)									
								});
								var selectOperations = []
								for (var i in unionsHash.keys()) {
									var setId = unionsHash.keys()[i];
									var selection = unionsHash.get(setId);
									selectOperations.push(new Select(new Load(setId), selection))
								}
								new Union(selectOperations).execute("json");
			                }
			            },
			            "Rename": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Rename",
			                "action": function (obj) { 
			                    tree.edit($node);
			                }
			            },                         
			            "Remove": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Remove",
			                "action": function (obj) { 
			                    tree.delete_node($node);
			                }
			            },
						"Trace_Image": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Trace Images",
			                "action": function (obj) { 
								var item = this_projection.xset.getItem($(obj.reference.parents()[0]).attr("item"));								
			                    this_projection.xset.traceImage(item);
			                }
							
						}
			        };			
				} else if(node.type === "Relation"){
					return {
						"Trace": common_menu_options,
			            "Applied To": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Relation Of",
			                "action": function (obj) { 
								alert("Relations of");
			                }
			            },
			            "Range": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Range",
			                "action": function (obj) { 
								alert("Range");
			                }
			            }
					};
				} else if(node.type === "Type"){
					return  {
						"Trace": common_menu_options,
			            "instances": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Items",
			                "action": function (obj) { 
								console.log($node.data.item);
								var type = $node.text;
								debugger;
								var f = function(data){
									var xset = new XPAIR.Xset(data.set);
									xset.setIntention("Instances of: " + type);
									var xsetAdapter = new XPAIR.adapters.JstreeAdapter(xset);
									new XPAIR.projections.Jstree(xsetAdapter).init();									
								}
								XPAIR.AjaxHelper.get('/session/instances.json?type=' + $node.data.item.replace("#", "%23"), "json", f);
			                }
			            },
			            "relations": {
			                "separator_before": false,
			                "separator_after": false,
			                "label": "Relations for this type",
			                "action": function (obj) { 
								alert("Relations");
			                }
			            }
					};
				} else if(node.type === "Xpair::Literal"){
					return  {
						"Trace": common_menu_options,
					};
				}
		    }
		};
		
	},
	
	this.showPathModal = function(){
		return function(){		
			var set_id = this_projection.xset.getId();
			var findRelations = new FindRelations(new Load(set_id));
			findRelations.execute("json", function(data){

				var items = data.set.extension;
				var relations_hash = new Hashtable();
				for(i in items){
					var item = items[i];
					for(j in item.relations){
						var relation = item.relations[j];
						relation.values = [];
						if(!relations_hash.containsKey(relation.id + relation.inverse)){
							relations_hash.put(relation.id+relation.inverse, relation);
						}
					}					
				}
				data.set.extension = relations_hash.values();

				var jstreeAdapter = new XPAIR.adapters.JstreeAdapter(new XPAIR.Xset(data.set));
				var jstreePath = new XPAIR.projections.JstreePath(jstreeAdapter);
				jstreePath.show();
			});			
		}
	},
		
	this.registerTreeSelectionBehavior = function($tree){
		$tree.on("select_node.jstree", function(event, data){

			var $node = $("#" + data.node.id);
			if(data.event == null){
				
				$node.addClass("SELECTED");
			} else{
			    if (!(data.event.shiftKey || (data.event.button == 2))) {
					$(".SELECTED").removeClass("SELECTED");
					$node.addClass("SELECTED");
			    } else {
					console.log("SHIFT PRESSED " +$node.attr("id") )
			        //If it was selected before, deselect. 
			        if ($node.hasClass('SELECTED')) {
			            $node.removeClass('SELECTED');
			        }
			        //If it was not selected before, select.
			        else {
						console.log("ADDING SELECTION TO: " + $node.attr("id"))
			            $node.addClass('SELECTED');
			        }
			        //If the window is selected, then does not select this element
			        if ($node.parents('._WINDOW.SELECTED').size() > 0) {
			            $node.removeClass('SELECTED');
			        }
			    }
			}
		});		
	},
	
	this.registerItemBehavior = function($tree){
		$($tree.jstree().get_json($tree, {
		  flat: true
		})).each(function(index, value) {
			var node = $tree.jstree().get_node(this.id);
			node.data = {item: node.text.trim()};
		});

		$tree.on("before_open.jstree", function (e, data) {

			var node_to_open = data.node

			for ( var i =0; i < node_to_open.children.length; i++) {
				var child = $tree.jstree().get_node(node_to_open.children[i])
				console.log(child);
				if (child.text === "Relations") {
					console.log("Deleting child: ");
					console.log(child);
					$tree.jstree().delete_node(child);
				}	
			}
			var event = e;
			var eventData = data;
	
			if(node_to_open.children.length == 0) {
				var tree_update_function = function(data, status, jqrequest) {

					var xset = new XPAIR.Xset(data.set);
					var jstreeAdapter = new XPAIR.adapters.JstreeAdapter(xset);
					var items = xset.getExtension();
					for (var i in items){
						var item = items[i];
						this_projection.getAdapter().addItem(node_to_open, item);

						for(var j in item.children){
							this_projection.getAdapter().addItem(item, item.children[j]);
						}
					}
				}
				var item_to_open_id = node_to_open.li_attr.item;
				var set_id = node_to_open.li_attr.set;

				//exploration expression
				var findRelations = new FindRelations(new Select(new Load(set_id), [item_to_open_id]));
				
				findRelations.execute("json", tree_update_function);
			}
		});		
	}
}
XPAIR.projections.Jstree.prototype = new XPAIR.projections.AbstractProjection();