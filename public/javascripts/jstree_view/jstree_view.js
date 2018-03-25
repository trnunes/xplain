XPLAIN.widgets = XPLAIN.widgets || {};

XPLAIN.widgets.JstreeView = function(parent, view){
	XPLAIN.widgets.Widget.call(this, parent, null);
	this.id = XPLAIN.guid();
	this.view = view
}

XPLAIN.widgets.JstreeView.prototype = Object.create(XPLAIN.widgets.Widget.prototype);

XPLAIN.widgets.JstreeView.prototype.build = function(){
	XPLAIN.widgets.Widget.prototype.build.call(this);
	debugger
	var setJson = this.getContextState().setJson;
	var $setView = $(this.view).parent();
	var $div = $("<div id = '"+this.id+"' class='_items_area'></div>");
	var setId = setJson.id;
	var thisView = this;
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
	    "plugins" : [ "types", "checkbox", "contextmenu", "search", "dnd", "state"],
	    "search" : {
            'case_sensitive' : false,
            'show_only_matches' : true,
			'ajax':{
				url: 'session/refine.json?set=' + setId,
				
				data: function(str) {
				  return { "set": setId, "search_str" : str };
				},
				
				success: function(data){
					$('#loadwindow').hide();
					return data.set.extension.map(function(item){

						var nodeid = $div.find("[item='"+item.id+"']").attr("id");
						if(!nodeid){
							item.resultedFrom =  $setView.attr('resultedFrom');
							item.set = setId;
							return thisView.addItem($div, "#", item);
						}
					});
				}
			}
        },
		"contextmenu": this.createTreeContextMenu($div)
	});
	
	//TODO create a method on controller register_keyword_search event
    var to = false;
    $setView.find('.search-input').keyup(function () {

      if(to) { 
		  clearTimeout(to); 
	  }
      to = setTimeout(function () {
		  
        var v = $("#" + setId + ' .search-input').val();
		if((v.length > 2) || (!v.length)){
			if(v.length){
				$('#loadwindow').show();
			}

			$div.jstree(true).search(v);
		}
        
      }, 250);
    });
	debugger;
	$div.jstree().hide_checkboxes();	
	this.registerBehavior($div);
	this.show($div);
	this.populate($div, setJson);
	this.view = $div;
	// this.registerMoveNodeBehavior();
}
	
XPLAIN.widgets.JstreeView.prototype.populate = function($jstreeListView, setJson){
		var jstree_nodes = [];
		var items = setJson.extension
		for (var i in items){
			this.addItem($jstreeListView, "#", items[i]);
		}		
	},
	
XPLAIN.widgets.JstreeView.prototype.registerBehavior = function($jstreeListView){
	this.registerTreeSelectionBehavior($jstreeListView);
	this.registerItemBehavior($jstreeListView);
},

XPLAIN.widgets.JstreeView.prototype.show = function($jstreeListView){
	
	$jstreeListView.show();
},

XPLAIN.widgets.JstreeView.prototype.clear = function(){

	if (typeof this.getDiv().jstree().uncheck_all !== "undefined") { 
		this.getDiv().jstree().uncheck_all();
		this.getDiv().jstree().hide_checkboxes();	    
	}

}

XPLAIN.widgets.JstreeView.prototype.clearTree = function($jstreeListView){

	$($jstreeListView.jstree().get_json($jstreeListView, {
	  flat: true
	})).each(function(index, value) {
		var node = $jstreeListView.jstree(true).delete_node(this.id);
	});
}

XPLAIN.widgets.JstreeView.prototype.updateText = function(items){
	for (var index in items){
		var item = items[index];
		$('[item="' + item.id + '"').each(function(){
			debugger;
			var $items_jstree = $(this).parents('._items_area.jstree');
			var item_node = $items_jstree.jstree().get_node($(this).attr('id'));
			if ($items_jstree.length){
				$items_jstree.jstree('rename_node', item_node , item.text);
			}
		
		});
	}
	
}

XPLAIN.widgets.JstreeView.prototype.onPageChange = function(eventJson){
	$jstreeListView = $('#' + this.id);
	this.clearTree($jstreeListView);
	this.populate($jstreeListView, this.getContextState().setJson);
}

XPLAIN.widgets.JstreeView.prototype.createTreeContextMenu = function($treeView){
	var $setView = $treeView.parent();
	var setId = $setView.attr('set')
	var selectSubmenu = {
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
				unionsHash.get(selected_node.li_attr.set).push(new Item(selected_node.li_attr));
			});
			var selectOperations = []
			for (var i in unionsHash.keys()) {
				var setId = unionsHash.keys()[i];
				var selection = unionsHash.get(setId);
				selectOperations.push(new Select(new Load(setId), selection))
			}
			new Union(selectOperations).execute("json");
        }
    };
	
	return {         
	    "items": function($node) {
		
	        var tree = $treeView.jstree(true);
			var node = $treeView.jstree().get_node($node.id);
			var common_menu_options = {}
			common_menu_options = {
				"label": "Trace Path",
				"action": function(obj){
					$(".SELECTED").each(function(){
						if ($setView.attr('resultedFrom')){
							console.log("tracing ", this);
							//TODO IMPLEMENT TRACE
							// this_projection.adapter.trace($(this));
						}
						
					});
				}
			};
			if (node.type === "Entity"){
		        return {
					// "Trace": common_menu_options,

		            "Select": selectSubmenu,
		            "Rename": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Rename",
		                "action": function (obj) { 
							//TODO fire itemRenamedEvent
		                    tree.edit($node);
		                }
		            },                         
		            "Remove": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Remove",
		                "action": function (obj) {
							//TODO fire itemRemovedEvent to the controller
		                    tree.delete_node($node);
		                }
		            }
		        };			
			} else if(node.type === "SchemaRelation"){
				return {
					"Select": selectSubmenu,
		            "Applied To": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Domain",
		                "action": function (obj) { 
					        var tree = $treeView.jstree(true);
							var node = $treeView.jstree().get_node($node.id);
							debugger;
							//TODO fire DomainRequestedEvent{relation: relation}
							var pivot = new Pivot(new Select(new Load($node.li_attr.set), [new Relation($node.li_attr)]));
							pivot.addRelation(new Relation({item: "xplain:domain", item_type: "SchemaRelation"}));
							pivot.execute("json");
		                }
		            },
		            "Range": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Images",
		                "action": function (obj) { 
					        var tree = $treeView.jstree(true);
							var node = $treeView.jstree().get_node($node.id);
							debugger;
							//TODO fire ImageRequestedEvent{relation: relation}
							var pivot = new Pivot(new Select(new Load($node.li_attr.set), [new Relation($node.li_attr)]));
							pivot.addRelation(new Relation({item: "xplain:range", item_type: "SchemaRelation"}));
							pivot.execute("json");
		                }
		            },
		            "Group": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Group set by",
		                "action": function (obj) { 
					        var tree = $treeView.jstree(true);
							var node = $treeView.jstree().get_node($node.id);
							debugger;	
							var group = new Group(new Load(setId));
							group.groupFunction = "by_relation"
							var relations = [new Relation(node.li_attr)];
							group.functionParams = {relations: relations};
							group.execute("json");
		                }
		            },
		            "Count": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Count related items",
		                "action": function (obj) { 
					        var tree = $treeView.jstree(true);
							var node = $treeView.jstree().get_node($node.id);
							debugger;
							var pivot = new Pivot(new Load(setId));
							pivot.addRelation(new Relation(node.li_attr));
							var group = new Group(pivot);
							group.groupFunction = "by_domain"
							var relations = [new Relation(node.li_attr)];
							group.functionParams = {domain_set: new XsetExpr(setId)};
							var map = new Map(group);
							map.mapFunction = "count";
							map.execute("json");
		                }
		            },
					
					
				};
			} else if(node.type === "Type"){
				return  {
					"Select": selectSubmenu,
		            "instances": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Items of this type",
		                "action": function (obj) { 
							console.log($node.data.item);
							var type = $node.text;
							
							var f = function(data){
								XPLAIN.SetController.appendToWorkspace(data.set)
							}
							
							var pivot = new Pivot(new Select(new Load($node.li_attr.set), [new Item($node.li_attr)]));
							pivot.addRelation(new Relation({item: "rdf:type", item_type: "SchemaRelation", inverse: true}))
							pivot.execute("json");
		                }
		            },
		            "relations": {
		                "separator_before": false,
		                "separator_after": false,
		                "label": "Relations for this type",
		                "action": function (obj) { 
							var pivot = new Pivot(new Select(new Load($node.li_attr.set), [new Item($node.li_attr)]));
							pivot.addRelation(new Relation({item: "xplain:ofType", item_type: "SchemaRelation"}));
							pivot.execute("json");
		                }
		            }
				};
			} else if(node.type === "Xpair::Literal"){
				return  {
					"Select": selectSubmenu,
					"Trace": common_menu_options,
				};
			}
	    }
	};
}
	
XPLAIN.widgets.JstreeView.prototype.registerTreeSelectionBehavior = function($tree){
	$tree.on("select_node.jstree", function(event, data){
		//TODO delegate to the controller method onItemsSelected
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
}

XPLAIN.widgets.JstreeView.prototype.registerItemBehavior = function($tree){
	var thisView = this;
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
				var items = data.set.extension;
				for (var i in items){
					var item = items[i];
					thisView.addItem($tree, node_to_open, item);
					for (var j in item.children){
						thisView.addItem($tree, item, item.children[j]);
					}
				}
			}				
			var item_to_open_id = node_to_open.li_attr;
			var set_id = node_to_open.li_attr.set;

			//exploration expression
			//TODO move this core to expandRelation(relation) or findRelations(item)
			if(node_to_open.li_attr.item_type == "SchemaRelation"){
				debugger;
				var item_id = $tree.jstree().get_node(node_to_open.parent).li_attr
				set_id = $tree.jstree().get_node(node_to_open.parent).li_attr.set
				var findRelations = new Pivot(new Select(new Load(set_id), [new Item(item_id)]));
				findRelations.relations = [new Relation(node_to_open.li_attr)]
			} else {
				var findRelations = new FindRelations(new Select(new Load(set_id), [new Item(item_to_open_id)]));
			}
			
			
			findRelations.execute("json", tree_update_function);
		}
	});		
}

XPLAIN.widgets.JstreeView.prototype.addItem = function($jstreeListView, parentNode, item){
	var jstreeItem = this.convertItem(item);
	var children = jstreeItem.children;
	
	$jstreeListView.jstree();
	var nodeId = $jstreeListView.jstree().create_node(parentNode, jstreeItem, "last", null, false);
	return nodeId;
}

XPLAIN.widgets.JstreeView.prototype.convertItem = function(item){
	var item_node = {
		text: item.text,
		type: item.type,
		data: {
			set: item.set, 
			item: item.id, 
			type: item.type,
			resultedFrom: item.resultedFrom
		},

		children: [],
		li_attr: {
			item: item.id,
			item_type: item.type,
			set: item.set,
			resultedFrom: item.resultedFrom
		}
	}
	
	if (item_node.type == "SchemaRelation"){
		item_node.li_attr.inverse = item.inverse
	}else if ((item.type == "Xpair::Literal") && item.datatype ){
		item_node.data.datatype = item.datatype;
		item_node.li_attr.datatype = item.datatype;
	}
	
	if (item.subset){
		item_node.subset = item.subset
		item_node.li_attr.subset = item.subset
	}

	if(item.children !== undefined && item.children.length > 0){
		for(var i in item.children){
			item_node.children.push(this.convertItem(item.children[i]))
		}
	} else {
		item_node.children.push({text: "Relations"});
	}

	return item_node;
	
}
	


