
XPLAIN.views = XPLAIN.views || {};


XPLAIN.views.RelationPathTree = function(setId, $treeDiv, params){
	this.setId = setId;
	this.selectedRelations = [];
	this.$treeDiv = $treeDiv;
	this.eventsTable = new Hashtable();
	this.params = params;
	this.currentSelection = [];
	var this_projection = this;
	this.getDiv = function(){
		return this.$treeDiv;
	},
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
		return this.currentSelection;
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
	//TODO Repeated code from jstree_view. Generalize it!
	this.populate = function(setJson){
		var jstree_nodes = [];
		var items = setJson.extension
		for (var i in items){
			this.addItem("#", items[i]);
		}		
	},
	this.addItem = function(parentNode, item){
		debugger;
		var jstreeItem = this.convertItem(item);
		var children = jstreeItem.children;
		
		this.$treeDiv.jstree();
		var nodeId = this.$treeDiv.jstree().create_node(parentNode, jstreeItem, "last", null, false);
		return nodeId;
	},
	
	this.convertItem = function(item){
		var item_node = {
			text: item.text,
			type: item.type,
			data: {
				set: item.set, 
				item: item.id, 
				type: item.type,
				resultedFrom: item.resultedFrom,
				dependencies: item.resultedFromArray 
			},

			children: [],
			li_attr: {
				item: item.id,
				item_type: item.type,
				set: item.set,
				resultedFrom: item.resultedFrom,
				dependencies: item.resultedFromArray
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
	
	this.loadData = function(expression){
		if (!this.$treeDiv.hasClass("jstree")) {
		  this.createTree();
		}
		expression.execute("json", function(data){
			debugger
			this_projection.populate(data.set);
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
			debugger;
			if(facetRelationNode.li_attr.inverse && this.allInverse(path)){
				path.push(new Relation(facetRelationNode.li_attr));
			}else{
				path.unshift(new Relation(facetRelationNode.li_attr));
			}
			
			parentRelation = this.$treeDiv.jstree().get_parent(facetRelationNode);
		}
		this.currentSelection = [new PathRelation(path)];

		this.notify("onBranchSelected", new PathRelation(path));
		
	},
	this.allInverse = function(path){
		var allInv = true;
		path.forEach(function(r){
			if(!(r.data.inverse)){
				allInv = false;
			}
		});
		return allInv
	}
}
