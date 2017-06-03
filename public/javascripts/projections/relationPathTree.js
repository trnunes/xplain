
XPAIR.projections = XPAIR.projections || {};


XPAIR.projections.RelationPathTree = function(xset, $treeDiv, params){
	this.xset = xset;
	this.adapter = null;
	this.selectedRelations = [];
	this.$treeDiv = $treeDiv;
	this.eventsTable = new Hashtable();
	this.params = params;
	var this_projection = this;
	this.getDiv = function(){
		return this.$treeDiv;
	}
	this.createTree = function($treeDiv){
		this.destroy();
		this.$treeDiv.jstree({
			"core": {
				"check_callback": true,

			},
			"checkbox" : {
		      "keep_selected_style" : true,
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
			this_projection.handleBranchSelection(e, data);
		});
		this.registerBehavior();
		this.$treeDiv.show();
	},
	
	this.registerBehavior = function(){
		
		this.$treeDiv.on("before_open.jstree", function (e, data) {
			e.stopPropagation();
			e.preventDefault();
			var checked_relation = data.node

			for ( var i =0; i < checked_relation.children.length; i++) {
				var child = this_projection.$treeDiv.jstree().get_node(checked_relation.children[i])

				if (child.text === "Relations") {
					this_projection.$treeDiv.jstree().delete_node(child);
				}		
			}

			if(checked_relation.children.length == 0) {
				this_projection.notify("onBranchOpened", checked_relation);
			}
		});		
	},
	
	this.registerHandler = function(event, handler){
		if(!this.eventsTable.containsKey(event)){
			this.eventsTable.put(event, []);
		}
		this.eventsTable.get(event).push(handler);
	},
	
	this.onBranchSelected = function(callback){
		this.registerHandler("onBranchSelected", callback);
	},
	
	this.onBranchDeselected = function(callback){
		this.registerHandler("onBranchDeselected", callback);
	},
	
	this.onBranchOpened = function(callback){
		this.registerHandler("onBranchOpened", callback);
	},
	
	this.onDismiss = function(callback){
		this.registerHandler("onDismiss", callback);
	},
	
	this.notify = function(event, data){
		var registeredCallbacks = this.eventsTable.get(event);
		debugger;
		if(registeredCallbacks){
			registeredCallbacks.forEach(function(callback){callback(data)});
		}
	},
	
	this.getSelection = function(){
		var checked_nodes = this_projection.$treeDiv.jstree().get_checked(true);
		that = this_projection;
		var leafNodes = [];
		
		checked_nodes.forEach(function(node){
			var firstChild = that.$treeDiv.jstree().get_node(node.children[0])
			var isLeafNode = (node.children.length == 1 && firstChild.text == "Relations");

			if (isLeafNode){
				leafNodes.push(node);
			}
		});
		var paths = []
		leafNodes.forEach(function(leafNode){
			debugger;
			parent_relation = that.$treeDiv.jstree().get_parent(leafNode);
			var path = [new Relation(leafNode.li_attr)];
			while(parent_relation !== "#") {
				var parent_relation_node = that.$treeDiv.jstree().get_node(parent_relation);
				path.unshift(new Relation(parent_relation_node.li_attr));
				parent_relation = that.$treeDiv.jstree().get_parent(parent_relation);
			}
			paths.push(new PathRelation(path));
		});
		return paths;
	},
	
	this.hide = function(){
		this.$treeDiv.hide();
		this.$treeDiv.jstree(true).uncheck_all();
		this.selectedRelations = [];
		this.notify("onDismiss", this);
	},
	
	this.restore = function(){
		this.show();
	},
	
	this.destroy = function(){
		if (this.$treeDiv.hasClass("jstree")) {
		  this.$treeDiv.jstree("destroy");
		}
	},
	
	this.clear = function(){
		$(this.$treeDiv.jstree().get_json(this.$treeDiv, {
		  flat: true
		})).each(function(index, value) {
			var node = this_projection.$treeDiv.jstree().get_node(this.id);
			node.data = {item: node.text.trim()};
			this_projection.$treeDiv.jstree().delete_node(node);
		});
	},
	
	this.loadData = function(expression){
		if (!this.$treeDiv.hasClass("jstree")) {
		  this.createTree();
		}
		
		var set_id = this_projection.xset.getId();
		
		expression.execute("json", function(data){
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
		});
	},
	
	this.show = function(){
		this_projection.$treeDiv.show();
	},
	
	this.handleBranchSelection = function(e, data){
		debugger;
		e.stopPropagation();
		e.preventDefault();
		
		var facetRelationSelected = data.node;
				
		var checked_nodes = this.$treeDiv.jstree().get_checked(true);
		checked_nodes.splice(checked_nodes.indexOf(facetRelationSelected.id));
		this.$treeDiv.jstree(true).uncheck_node(checked_nodes);
		

		path = [];


		var parentRelation = this.$treeDiv.jstree().get_parent(facetRelationSelected);

		path.push(new Relation(facetRelationSelected.li_attr));
		
		while(parentRelation !== "#") {
			
			facetRelationNode = this.$treeDiv.jstree().get_node(parentRelation);
			path.unshift(new Relation(facetRelationNode.li_attr));
			parentRelation = this.$treeDiv.jstree().get_parent(facetRelationNode);
		}

		this.notify("onBranchSelected", new PathRelation(path));
		
	}
}
