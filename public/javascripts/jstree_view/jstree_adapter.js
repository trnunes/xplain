XPLAIN.adapters = XPLAIN.adapters || {};
//TODO move this to the jstree_view 
function PageState(){
	this.nodesState = new Hashtable();
	this.selectedNodes = new Hashtable();
	var that = this;
	this.savePageState = function($tree){
		$tree.find(".SELECTED").each(function(){
			that.selectedNodes.put($(this).attr("item"), "selected");
		});
		var checked_nodes = []

		$tree.find(".jstree-checked").each(function(){
			$(checked_nodes.push($(this).parents()[0])).attr("id");
		});
		$tree
		for(var i in checked_nodes){
			var node = $tree.jstree(true).get_node(checked_nodes[i]);

			if(node.li_attr){
				if(node.li_attr.item){
					this.nodesState.put(node.li_attr.item, "checked");
				}
			}			
		}
	},
	
	this.restoreNodesState = function($tree){
		for(var i in this.nodesState.keys()){
			var nodeItem = this.nodesState.keys()[i];
			var nodeIdInTree = $tree.find("[item='"+nodeItem+"']").attr("id");
			$tree.find("#" + nodeIdInTree).attr("aria_selected", true);
			$tree.find("#" + nodeIdInTree).find("#"+ nodeIdInTree + "_anchor").addClass("jstree-checked");
			
			// $tree.jstree(true).check_node(nodeIdInTree);
		}
		for(var i in this.selectedNodes.keys()){
			var nodeItem = this.selectedNodes.keys()[i];
			var nodeIdInTree = $tree.find("[item='"+nodeItem+"']").addClass("SELECTED");
			
			// $tree.jstree(true).check_node(nodeIdInTree);
		}
		
	}

};

XPLAIN.adapters.JstreeAdapter = function(xset){
	this.projection = null;
	this.xset = xset;
	
	this.currentPage = this.xset.getCurrentPage();
	this.xset.addObserver(this);
	this.pagesHash = new Hashtable();


	var this_adapter = this;
	this.projectionMap = new Hashtable();
	
	this.setProjection = function(projection){
		this.projection = projection;
	},
	this.clear = function(){
		this.pagesHash = new Hashtable();
	},
	this.getXset = function(){
		return this.xset;
	},
	
	//TODO move this to the jstree view 
	this.update = function(xset, newData, event){
		
		if(event == "pageChange"){
			
			var pageState = new PageState();
			pageState.savePageState(this.projection.getDiv());
			this.pagesHash.put(xset.getPreviousPage(), pageState);
			this.recreate(newData.extension);
			if(this.pagesHash.get(xset.getCurrentPage())){
				pageState = this.pagesHash.get(xset.getCurrentPage());
				pageState.restoreNodesState(this.projection.getDiv());
			}
		} else {
			this.recreate(newData.extension);
		}
		

		
	},
	//TODO REMOVE
	this.trace = function(item) {
		var origin_set_id = $(item).attr("set");
		
		var item_subset = $(item).attr("subset")
		var url = ""
		if (item_subset) {
			url = "/session/trace_subset_domains.json?set="+ origin_set_id+ "&subset=" + item_subset
		} else {
			url = "/session/trace_item_domains.json?set="+ origin_set_id+ "&item=" + $(item).attr("item")
		}
		XPLAIN.AjaxHelper.get(url, "json", function(data){
		
			for(var i in data) {
				var local_domains = data[i].domains;
				var set_id = data[i].id
				for( var j = 0; j < local_domains.length; j++){
					var domain_item = local_domains[j]
					;
					if (domain_item.type == "Xsubset"){
						$($("#" + set_id).find("[subset='"+domain_item.id+"']")).addClass("SELECTED");
					} else {
						$($("#" + set_id).find("[item='"+domain_item.id+"']")).addClass("SELECTED");
					}
				}
			}
		});
	},
	
	//TODO consider removing
	this.renderLevel = function(level){
		
		var $tree = this_adapter.projection.getDiv();
		$tree.jstree().deselect_all();
		$('.SELECTED').removeClass("SELECTED");	
		parameters.put("level", level)
	    $($tree.jstree().get_json($tree, {
	        flat: true
	    })).each(function () {
			var node = $tree.jstree().get_node(this.id);
	        var node_level = node.parents.length;

	        if (node_level == level) {
				if(node.text != "Relations"){
					$tree.jstree().select_node(this.id)
				}	            
	        }
	    });

	},
	//TODO move to the view class
	this.convertItem = function(item){
		
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
	},
	
	//TODO move to the view class consider creating a method add_edge in the view
	this.updateItem = function(itemToUpdate){		
		var $tree = this.projection.getDiv();
		$($tree.jstree().get_json($tree, {
		  flat: true
		})).each(function(index, value) {
			var node = $tree.jstree().get_node(this.id);
			if(node.data != null && node.data.item == itemToUpdate.id){
				var jstreeItem = this_adapter.convertItem(itemToUpdate, true);
				for(var i in jstreeItem.children){
					$tree.jstree().create_node(node, jstreeItem.children[i], "last", null, false);
				}
				return;
			}
		});		
		
	},
	
	//deprecated! Use the function populate to populate the tree after its creation.
	this.convertFormat = function(){
		var jstree_nodes = [];
		var items = xset.getExtension();
		for(var i in items){
			var jstreeItem = this.convertItem(items[i]);
			jstree_nodes.push(jstreeItem)
			
		}		
		
		return jstree_nodes;
	},
	
	//TODO move all above methods to the view class and eliminate the adapter
	this.recreate = function(xsetExtension){
		this.clearTree();
		
		this.createTree(xsetExtension);
	},
	this.populate = function(){
		this.createTree(this.xset.getExtension());
	},
	this.clearTree = function(){
		var $tree = this.projection.getDiv();
		$($tree.jstree().get_json($tree, {
		  flat: true
		})).each(function(index, value) {
			var node = $tree.jstree(true).delete_node(this.id);
		});		
		
	},
	this.createTree = function(items){
		var jstree_nodes = [];

		for(var i in items){
			this.addItem("#", items[i]);
		}
		var $tree = this.projection.getDiv();
		$($tree.jstree().get_json($tree, {
		  flat: true
		})).each(function(index, value) {
			var node = $tree.jstree().get_node(this.id);
			if(node.data != null){
				if(this_adapter.projectionMap.get(node.data.item) == null){
					this_adapter.projectionMap.put(node.data.item, []);
				}
				this_adapter.projectionMap.get(node.data.item).push(node.id);
			}			
		});
		
	}
};
