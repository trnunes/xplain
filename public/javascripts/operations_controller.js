
var XPAIR = XPAIR || {};
XPAIR = {
	currentOperation: null,
	currentSession: null,
	getType: function(f){
		return f.constructor.name;
	},
	Operations: {
		pivot: "pivot",
		refine: "refine",
		group: "group",
		map: "map",
		merge: "merge",
		findPath: "findPath"
	},	
	addParameter: function(parameterId, $view){
		parameters.put(parameterId, $view);
		$view.addClass(parameterId);
		$(".SELECTED").removeClass("SELECTED");
	},
	getOperation: function(operationName, setId){
		if (operationName === "pivot"){

			XPAIR.currentOperation = XPAIR.currentOperation || new Pivot(new Load(setId));
			if (XPAIR.currentOperation.type() !== "Pivot"){
				XPAIR.currentOperation = new Pivot(new Load(setId));
			}			
		} else if (operationName === "refine"){
			XPAIR.currentOperation = XPAIR.currentOperation || new Refine();
			if (XPAIR.currentOperation.type() !== "Refine"){
				XPAIR.currentOperation = new Refine();
			}			
		}
		return XPAIR.currentOperation;		
	},
	calculate: function(expression){
		new Expression(expression).execute("json");
	},
	generateExpressionFromSelection: function($selection){
		var unionsHash = new Hashtable();
		var setUnions = []
		$selection.each(function(){
			if ($(this).hasClass("set")){
				setUnions.push(new Load($(this).attr("id")));
			} else {
				var selectedItemSet = $(this).attr("set");
				var selectedItemId = $(this).attr("item");

				if(!unionsHash.containsKey(selectedItemSet)){
					unionsHash.put(selectedItemSet, []);
				}
				unionsHash.get(selectedItemSet).push(selectedItemId)				
			}
		});
		var operations = []
		for (var i in unionsHash.keys()) {
			var setId = unionsHash.keys()[i];
			var selection = unionsHash.get(setId);
			operations.push(new Select(new Load(setId), selection))
		}
		for (var i in setUnions){
			operations.push(setUnions[i]);
		}
		
		if (operations.length > 1){
			return new Union(selectOperations);	
		}else{
			return operations[0];
		}	
	}
}

//TODO generalize the inputFunction param
function Operation(){
	this.dependsOn = null;
	this.errorMessages = [];

};
Operation.prototype.getType = function(){
	return this.constructor.name;
};
Operation.prototype.addErrorMessage = function(errorMessage){
	this.errorMessages.push(errorMessage);
};
Operation.prototype.getErrorMessages = function(){
	return this.errorMessages;
};
Operation.prototype.clearMessages = function(){
	this.errorMessages = [];
};
Operation.prototype.getInputSets = function(inputSets){

	if(this.inputFunction){
		if(this.inputFunction.constructor.name == "Array"){
			for(i in this.inputFunction){
				this.inputFunction[i].getInputSets(inputSets);
			}
			
		} else {
			this.inputFunction.getInputSets(inputSets);
		}
		
	} else {
		inputSets.push(this.setId);
	}

};
Operation.prototype.generateParamsExpr = function(){
	paramsExpr = ""
	
	jQuery.each(this.functionParams, function(paramName, paramValues){
		

		paramsExpr += paramName + ": ";
		if (!(paramValues.constructor.name == "Array")){
			paramValues = [paramValues]
		}
		
		paramsExpr += paramValues.map(function(values){
			var values_array = values;
			if (!(values.constructor.name == "Array")){
				values_array = [values]
			}
			var valuesExpr = values_array.map(function(value){
				var expr = "";
				
				if(value.constructor.name == "Operation"){
					expr = value.getExpression(); 
				} else if((typeof value == "object")) {
				
					expr = value.item_type + ".new('"+value.item.replace("#", "%23")+"')";
				} else {
					expr = "'" + value + "'";
				}
				return expr;
			}).join(",");
			debugger;
			if (values.constructor.name == "Array"){
				valuesExpr = "["+valuesExpr+"]"
			}
			return valuesExpr;
		}).join(",");
		paramsExpr += ",";

	});
	return paramsExpr;
	
};

Operation.prototype.execute = function(format, successFunction){
	var that = this
	if(this.validate()){
		XPAIR.AjaxHelper.execute(this.getExpression(), successFunction || function(data){
			debugger;
			var xsetAdapter = new XPAIR.adapters.JstreeAdapter(new XPAIR.Xset(data.set, that));
			new XPAIR.projections.Jstree(xsetAdapter).init();
		}, format);		
	} else {
		for (var i in this.errorMessages){
			alert(this.errorMessages[i]);
		}
		this.clearMessages();
		return false;
	}
	return true;
		
	
};


function Pivot(inputFunction, level) {	
	if(!level){
		var level = 1;
	}
	this.level = level;
	this.path = [];
	this.relations = [];
	this.isForward = true;
	this.inputFunction = inputFunction;

	this.setParams = function(params){
		var isPath = false;
		if(params.containsKey("isPath")){
			isPath = params.get("isPath");
		}
		
		if(params.containsKey("relations")){
			var targetRelations = params.get("relations");
			
			// if (targetRelations.length == 1) {
			// 	var parentRelations = [];
			//
			// 	parentRelations = $(targetRelations[0]).parents("[item_type=Relation].SELECTED");
			//
			// 	parentRelations.push(targetRelations[0]);
			// 	targetRelations = parentRelations
			// 	isPath = true;
			//
			// }
			
		}
		

		for(var i=0; i< targetRelations.length; i++) {
			var relationId = $(targetRelations[i]).attr("item");
			if(isPath){
				this.appendToPath(relationId);
			} else {
				this.addRelation(relationId);		
			}
		}
	
		if (targetRelations.length == 1 && eval($(targetRelations[0]).attr("inverse"))){
			this.backward(true);
		}
	},
	this.backward = function(boolean){
		this.isForward = !boolean;
	},
	this.appendToPath = function(relationId){
		this.path.push(relationId);
	},
	this.insertToPath = function(relationId){
		this.path.unshift(relationId);
	},
	this.getPath = function(){
		return this.path;
	},
	this.addRelation = function(relationId){
		this.relations.push(relationId);
	},
	this.containsRelation = function(relationId){
		return (this.path.indexOf(relationId) >= 0 || this.relations.indexOf(relationId) >= 0);
	},
	
	this.removeRelation = function(relationId){
		var index = this.path.indexOf(relationId);
		if (index >= 0){
			for(var i = 0; i <= index; i++) {
				this.path.splice(i);
			}			
		} else {
			index = this.relations.indexOf(relationId);
			this.relations.splice(index);
		}		
	},
	//private
	//TODO implement validation
	this.validate = function() {
		
		this.clearMessages();
		if(!this.inputFunction){
			this.addErrorMessage("You must select one of the sets in the exploration area for this operation!");
			return false;
		}
		
		if((this.relations.length == 0) && (this.path.length == 0)){
			this.addErrorMessage("You must select at least one relation in the exploration area to pivot!");
			return false;
		}
		return true;
			
	},
		
	this.getRelationExpr = function() {
		var relation_expr = "";	
		var isPath = (this.path.length > 0);
		var relations = []
		if (isPath) {
			relations = this.path;
		} else {
			relations = this.relations;
		}		
		for(var i in relations) {
			relation_expr += "'" + encodeURI(relations[i]).replace(/#/g, '%23') + "',"
		}
		if (isPath) {
			relation_expr = "[[" + relation_expr + "]]"
		} else {
			relation_expr = "[" + relation_expr + "]"
		}
		return relation_expr;
	},
	
	this.getExpression = function(){

		var setExpr = this.inputFunction.getExpression();
		var pivotExpr = "";
		if (this.isForward) {
			pivotExpr = ".pivot_forward(";
		}else {
			pivotExpr = ".pivot_backward(";
		}
		pivotExpr += this.getRelationExpr();

		pivotExpr += ")";
		return setExpr + pivotExpr;		
	},
	this.type = function(){
		return "Pivot";
	}
};
Pivot.prototype = new Operation();

function Merge(inputFunction, targetFunction){
	this.inputFunction = inputFunction;
	this.targetFunction = targetFunction;
	
	this.getExpression = function(){
		return this.inputFunction.getExpression() +".merge!(["+this.targetFunction.getExpression()+"])";
	},
	this.type = function(){
		return "Merge";
	},
	this.validate = function(){
		this.clearMessages();
		return true;
	}
	
};
Merge.prototype = new Operation();

function FindRelations(inputFunction){
	this.inputFunction = inputFunction;

	this.getExpression = function(){
		var expression = ".pivot()";
		expression = this.inputFunction.getExpression() + expression;
		return expression;
	},
	this.type = function(){
		return "Refine";
	},
	this.validate = function(){
		this.clearMessages();
		if(this.inputFunction) {
			return this.inputFunction.validate();
		} else {
			return false
		}
		
		return true;
	}
	
};
FindRelations.prototype = new Operation();

function Select(inputFunction, selection){
	this.inputFunction = inputFunction;
	this.selection = selection;
	
	this.getExpression = function(){
		var selectionExpr = "[";
		for(var i in this.selection){
			selectionExpr += "Entity.new('"+this.selection[i].replace("#", "%23")+"'),"
		}
		selectionExpr += "]"
		
		var expression = this.inputFunction.getExpression() + ".select_items("+selectionExpr+")";
		return expression;
	},
	this.type = function(){
		return "Select";
	},
	this.validate = function(){
		this.clearMessages();
		if(this.inputFunction) {
			return this.inputFunction.validate();
		} else {
			return false
		}
		
		return true;
	}
	
};
Select.prototype = new Operation();

function Refine(inputFunction){
	this.inputFunction = inputFunction;
	this.params = parameters;
	this.filter = null;
	this.functionParams = {connector: 'AND'};
	this.connector = "AND";
	// this.filterParams = {};
	this.relations = [];

	this.setParams = function(params){
		var valuesArray = params.get("values");
		var filterParams = {};

		relations = []
		
		var that = this;
		if(params.containsKey("filter")){
			this.filter = params.get("filter");
		}
		if(params.containsKey("relation")){
			params.get("relation").each(function(){
				if ($(this).hasClass("set")) {
					relations.push(new Expression($(this).attr("exp")));
					that.setFilter("image_equals")
				} else {
					relations.push({item: $(this).attr('item'), item_type: $(this).attr("item_type")});				
				}

			});
			filterParams.relations = [relations];
		}

		if(params.containsKey("values")){
			var values = []
			for (var index =0; index < valuesArray.length; index++){
				 values.push({item: $(valuesArray[index]).attr("item"), datatype: $(valuesArray[index]).attr("datatype"), item_type: $(valuesArray[index]).attr("item_type")});
				 if (relations.length == 0){
					 
					 relations.push(new Load($(valuesArray[index]).attr("set")));
					 that.setFilter("image_equals");
				 }
			}
			if(values.length > 0) {
				filterParams.values = values;
			}
			
		}

		this.setFilterParams(filterParams);
		
	},
	this.setConnector = function(connector){
		this.functionParams.connector = connector;
	},
	this.equals = function(relations, values){
		this.filter = "equals";
		if((relations.length > 0) && (relations[0].constructor.name == "Operation")){
			this.filter = "image_equals";
		}
		
		this.functionParams.relations = [relations];
		if(values.constructor.name == "Array"){
			values = [values]
		}
		this.functionParams.values = values;
	},
	this.contains = function(relations, values){
		this.filter = "contains_one";
		this.functionParams.relations = [relations]
		this.functionParams.values =  values;
	},
	this.setFilter = function(filter){
		this.filter = filter;
	},
	this.setFilterParams = function(params){
		this.functionParams = params;
	},
	this.validate = function(){
		
		this.clearMessages();
		if(!this.filter){
			this.addErrorMessage("You must select one filter to apply!");
			return false;
		}
		if(this.filter == "keyword_match"){

			if(!(this.functionParams.keywords || this.functionParams.keywords.length != 0)){
				$("#seachbykeyword").toggleClass("blink-class");
				this.addErrorMessage("Type one or more keywords in the keyword input, please!");
				return false;
			}
		} else {
			if(!this.functionParams.values){
				this.addErrorMessage("You must select at least one relation value to filter!");
				return false;
			}
			if(!this.functionParams.relations){
				this.addErrorMessage("Select a relation or a relation set for the filter!");
				return false;
			}
		}
		return true;
			
	},
	this.getExpression = function(){
		var filterParams = this.generateParamsExpr();		
		
		return inputFunction.getExpression() + ".refine{|f|f."+this.filter+"("+filterParams+")}";
	}
};
Refine.prototype = new Operation();

function FacetedSearch(inputFunction){
	this.inputFunction = inputFunction;
	this.facets = [];
	this.connector = "AND";
	
	this.addFacet = function(relation, value, connector){
		
		var added = false;
		for(var i in this.facets){
			debugger;
			if(this.equalFacets(this.facets[i][0], relation)){
				this.facets[i][1].push(value);
				if(connector){
					this.facets[i].push(connector);
				}
				
				added = true;
			}
			
		}
		
		if(!added){
			this.facets.push([relation, [value]])
		}
		
	},
	
	this.equalFacets = function(facet1, facet2){
		debugger;
		var relationComparable;
		var relationToRemoveComparable;
		if(facet1.constructor.name == "Operation"){
			relationComparable = facet1.getExpression();
		} else {
			relationComparable = facet1.item
		}
		if(facet2.constructor.name == "Operation"){
			relationToRemoveComparable = facet2.getExpression();
		} else{
			relationToRemoveComparable = facet2.item
		}
		
		return (relationComparable == relationToRemoveComparable)
	},
	this.setConnector = function(connector){
		this.connector = connector;
	},
	this.removeFacet = function(relationToRemove, valueToRemove){
		
		for (var i in this.facets){
			var relation = this.facets[i][0];
			var values = this.facets[i][1];
			var index = -1
			for(var j in values){
				if (values[j].item == valueToRemove.item){
					index = j;
				}
			}

			if((this.equalFacets(relation, relationToRemove)) && (index >= 0)){
				values.splice(index);
				if(values.length == 0){
					this.facets.splice(i);
				}
			}	
		}
	},
	this.getExpression = function(){
		var refineOperations = [];
		var facetedSearch = null;
		
		for(var i in this.facets){
			var facet = this.facets[i];
			var refineOp = new Refine(this.inputFunction);

			refineOp.equals([facet[0]], facet[1]);
			if(facet[2]){
				refineOp.setConnector(facet[2]);
			}
			
			refineOperations.push(refineOp);
		}
		
		if(refineOperations.length > 1){
			if(this.connector == "AND"){
				facetedSearch = new Intersection(refineOperations);
			} else {
				facetedSearch = new Union(refineOperations);
			}			
		} else {
			facetedSearch = refineOperations[0];
			facetedSearch.setConnector(this.connector);
		}
			
		return facetedSearch.getExpression();
	},
	
	this.validate = function(){
		this.clearMessages();
		if(this.facets.length == 0){
			this.addErrorMessage("Please select at least one value to filter!")
			return false;
		}
		return true;
	}
	
	
};
FacetedSearch.prototype = new Operation();

function Union(functions){
	this.inputFunction = functions;
	
	this.getExpression = function(){
		if(this.validate()){
			var union = this.inputFunction[0].getExpression();
			for(var i=1; i < this.inputFunction.length; i++) {
				union += ".union(" +this.inputFunction[i].getExpression()+")";
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return union;
	},
		
	this.validate = function(){
		this.clearMessages();
		if(this.inputFunction.length == 0){
			this.addErrorMessage("Please select at least one set to unite!");
			return false;
		}
		return true;
	}
};
Union.prototype = new Operation();

function Intersection(functions){
	this.functions = functions;
	
	this.getExpression = function(){
		if(this.validate()){
			this.clearMessages();
			var union = functions[0].getExpression();
			for(var i=1; i < functions.length; i++) {
				union += ".intersect(" +functions[i].getExpression()+")"
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return union;
	},
		
	this.validate = function(){
		this.clearMessages();
		if(this.functions.length == 0){
			this.addErrorMessage("Please select at least one set to intersect!");
			return false;
		}
		return true;
		
	}
};
Intersection.prototype = new Operation();

function Difference(functions){
	this.functions = functions;
	
	this.getExpression = function(){
		if(this.validate()){
			this.clearMessages();
			var diff = functions[0].getExpression();
			for(var i=1; i < functions.length; i++) {
				diff += ".diff(" +functions[i].getExpression()+")"
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return diff;
	},
	this.validate = function(){
		this.clearMessages();
		if(this.functions.length == 0){
			this.addErrorMessage("Please select at least one set to diff!");
			return false;
		}
		return true;
		
	}
};
Difference.prototype = new Operation();

//TODO include a param that is the list of params for the chosen map function
function Map(inputFunction, level){
	if(!level){
		var level = 1;
	}
	this.inputFunction = inputFunction;
	this.mapFunction = null;

	this.level = level;
	
	this.setFunction = function(mapFunction){
		this.mapFunction = mapFunction;
	},
	
	this.setFunctionParams = function(mapFunctionMaps){
		this.functionParams = mapFunctionMaps;
	},
	
	this.getExpression = function(){
		if(this.validate()){
			
			var expression = this.inputFunction.getExpression();
			var functionExpression = this.mapFunction;
			if(this.functionParams != null && this.functionParams.length > 0){
				functionExpression += "(["+ this.functionParams.join(",")+"])"
			}
			expression += ".map(level:"+this.level+"){|f| f."+functionExpression+"}";
			return expression;
		}else {
			alert("Not Valid Expression!");
		}
	},
	this.validate = function(){
		this.clearMessages();
		if(!this.mapFunction){
			this.addErrorMessage("Please select a mapping function to apply!");
			return false;
		}
		return true;
		
	}	
};
Map.prototype = new Operation();

function Group(inputFunction, level){
	if(!level){
		var level = 1
	}
	
	this.inputFunction = inputFunction;
	this.level = level;
	
	this.setParams = function(params){
		groupParams = {}
		
		if(params.containsKey("groupingFunction")){
			this.setFunction(params.get("groupingFunction"));
		}
		if(this.groupFunction == "by_relation"){
			if(params.containsKey('relations')){
				var relationsArray = params.get('relations')
				var paramValues = [];
	
				relationsArray.each(function(){
					if ($(this).hasClass("set")) {
						paramValues.push(new Expression($(this).attr("exp")));
					} else {
						paramValues.push({item: $(this).attr('item'), item_type: $(this).attr("item_type")});				
					}
				});
				if(paramValues.length > 0){
					groupParams.relations = [paramValues];
				}
			}			
		}
		
		this.setFunctionParams(groupParams);	
		
	},
	this.setFunction = function(groupFunction){
		this.groupFunction = groupFunction;
	},
	this.setFunctionParams = function(functionParams){
		this.functionParams = functionParams;
	},
	//TODO implement validate
	this.validate = function(){
		this.clearMessages();
		if(!inputFunction){
			this.addErrorMessage("Please select a set to group!");
			return false;
		}
		if(!this.groupFunction){
			this.addErrorMessage("You must choose a grouping function for this operation!");
			return false;
		}
		if(this.groupFunction == "by_relation"){
			
			if (!(this.functionParams.relations && this.functionParams.relations.length > 0)){
				this.addErrorMessage("You must select a relation or a relation set in the exploration area!");
				return false;
			}
			
		}
		return true;
		
	},
	this.getExpression = function(){
		var groupParamsExp = "";

		
		groupParamsExp = this.generateParamsExpr();
		
		return inputFunction.getExpression() + ".group{|gf|gf."+this.groupFunction+"("+groupParamsExp+")}";
		
	}
}
Group.prototype = new Operation();

function Rank(inputFunction){
	this.inputFunction = inputFunction;
	this.rankFunction = null;
	this.functionParams = null;
	this.order = null;
	this.setParams = function(params){
		functionParams = {}
		
		if(params.containsKey("order")){
			this.order = params.get("order");
		}

		if(params.containsKey("ranking_function")){
			this.setFunction(params.get("ranking_function"));
		}
		
		if(this.rankFunction == "by_relation"){
			if(params.containsKey("relations")){
				var valuesArray = params.get("relations");
				var paramValues = [];
				valuesArray.each(function(){
					if ($(this).hasClass("set")) {
						paramValues.push(new Expression($(this).attr("exp")));
					} else {
						paramValues.push({item: $(this).attr('item'), item_type: $(this).attr("item_type")});				
					}
				});
				if(paramValues.length > 0){
					functionParams.relations = [paramValues]
				}
			}
		}
	
		this.setFunctionParams(functionParams);
		
	},
	this.setFunction = function(rankFunction){
		this.rankFunction = rankFunction
	},
	this.setFunctionParams = function(rankFunctionParams){
		this.functionParams = rankFunctionParams;
	},
	this.validate = function(){
		this.clearMessages();
		if(!this.inputFunction){
			this.addErrorMessage("Please select a set to rank!");
			return false;
		}
		if(!this.rankFunction){
			this.addErrorMessage("Please select a ranking function to rank the set!");
			return false;
		}
		
		if(this.rankFunction == "by_relation"){
			if(!this.functionParams.relations){
				this.addErrorMessage("You must select at least one relation/relation set for ranking!");
				return false;
			} else if(this.functionParams.relations.length == 0){
				this.addErrorMessage("You must select at least one relation/relation set for ranking!");
				return false;
			}
		}
		return true;
	},
	this.getExpression = function(){
		var rankParamsExp = "";
		var rankParams = {};
		
		if(this.validate()){
			rankParamsExp = this.generateParamsExpr();
			var constructor = ""
			if(this.order){
				constructor = "{order: '" + this.order + "'}";
			}
			
		
			return inputFunction.getExpression() + ".rank("+constructor+"){|gf|gf."+this.rankFunction+"("+rankParamsExp+")}";
			
		} else {
			alert("Invalid expression!");
		}
	}
}
Rank.prototype = new Operation();

function Load(setId){
	this.setId = setId;
	this.getExpression = function(){
		return "Xset.load('"+this.setId.replace("#", "%23")+"')";
	},
	this.validate = function(){
		return true;	
	}
}
Load.prototype = new Operation();
function Flatten(inputFunction){
	this.inputFunction = inputFunction;
	this.getExpression = function(){
		return this.inputFunction.getExpression() + ".flatten"
	},
	this.validate = function(){
		return true;
	}
}
Flatten.prototype = new Operation();
function Expression(expression){
	this.expression = expression
	this.getExpression = function(){ return this.expression;},
	this.validate = function(){
		return true;
	}
}
Expression.prototype = new Operation();

function Project(inputFunction, relation){
	this.inputFunction = inputFunction;
	this.relation = relation;
	this.getExpression = function(){
		return this.inputFunction.getExpression() + ".project(Relation.new('" + this.relation.replace("#", "%23") + "'))"
	},
	this.validate = function(){
		return true;
	}
	
}
Project.prototype = new Operation();

function TraceDomains(inputFunction, item){
	this.inputFunction = inputFunction;
	this.item = item;
	
	this.getExpression = function(){
		return this.inputFunction.getExpression() + ".trace_domains("+item.type+".new('"+item.id+"')";
	},
	this.validate = function(){
		return true;
	}
	
}
TraceDomains.prototype = new Operation();

XPAIR.Xset = function(data, operation){	

	this.$view = null;
	var this_set = this;
	this.generates = [];
	this.observers = [];
	this.generatedByOperation = operation
	this.itemsHash = new Hashtable();
	this.page = 1;
	this.previousPage = 1;
	this.intention = null

	this.setIntention = function(intention){
		this.intention = intention;
	},
	this.levelChangeListener = null;
	this.setData = function(data){
		this.data = data;
		if(this.data.resultedFrom){
			var resultedFromSet = XPAIR.currentSession.getSet(this.data.resultedFrom);
			if(resultedFromSet){
				resultedFromSet.addGenerates(this);
			}
		}
	},
	this.setData(data);
	
	this.addGenerates = function(generatedSet){
		this.generates.push(generatedSet);
	},
	this.getGenerates = function(){
		return this.generates;
	},
	this.populateItemsHash = function(){
		var obj = this.data.extension;

		for(var i in obj){

			var item = obj[i]
			if(item.type) {
				this_set.itemsHash.put(item.id, item);
			}
			var children = item.children || [];
			while(children.length > 0){
				var next_children = []
				children.forEach(function(child){ 

					if(child.type) {
						this_set.itemsHash.put(child.id, child);
						if(child.children) {
							child.children.forEach(function(item){

								next_children.push(item);
							});
						}
					}
				});
				children = next_children;
			}
		}
	};
	this.populateItemsHash();
	this.getView = function(){
		debugger;
		if (this.$view == null){
			this.createEmptyView();
		}
		return this.$view;
	},
	this.traceDomain = function(item, callback){
		console.log("TRYING TRACE DOMAIN FOR: ", item);
		XPAIR.AjaxHelper.get("/session/trace_domains.json?set="+ this.getId()+ "&subset=" + item.id, "json", function(data){
			console.log("TRACE DATA: ", data);
			callback(data);
		});
		
	},
	this.traceImage = function(item){
		XPAIR.currentSession.getSet(item.attr("generates"))
		for(var i in item.parents){
			var parentItem = item.parents[i];
			$("li[item='" + parentItem.id + "']").addClass("SELECTED");
			this.traceImage(parentItem);
		}
	},
	
	
	this.traceDomains = function(item){
		
	},
	
	this.addObserver = function(observer){
		this.observers.push(observer);
	},
	this.notify = function(newData, event){
		for(var i in this.observers) {
			this.observers[i].update(this, newData, event);
		}	
	},
	
	this. getLeafNodes = function(leafNodes, obj){
	    if(obj.children){
	        obj.children.forEach(function(child){getLeafNodes(leafNodes,child)});
	    } else{
	        leafNodes.add(obj);
	    }
	},
	
	this.registerLevelChangeListener = function(listener){
		this.levelChangeListener = listener;
		this.getView().find('#select_levels_list input[type=radio]').each(function(){
			$(this).unbind().change(function(event){				
				listener(parseInt(this.value));
			})
		});
	},
	
	this.getLevel = function(level, callback){
		var levelUrl = "/session/get_level.json?set="+this.getId()+"&level="+ level
		XPAIR.AjaxHelper.get(levelUrl, "json", callback);		
	},
	
	this.updateLevelsCount = function(levelsCount){
		var first_level_project = this.$view.find("#project_levels_list").children()[0]
		var first_level_select = this.$view.find("#select_levels_list").children()[0]
 
		$(first_level_select).nextAll().remove();
		$(first_level_project).nextAll().remove();
		for(var i=1; i < levelsCount; i++){
			level_view = $(first_level).clone()
			level_view.find("label").html("<input type=\"radio\" name=\"filterradio\" class=\"param\" param=\"filter\" param_value=\"equals\" value=\""+(i+1)+"\"> Level" + (i+1));
			this.$view.find(".levels_list").append(level_view);
		}
		if(this.levelChangeListener != null){
			this.registerLevelChangeListener(this.levelChangeListener);
		}
		this.registerProjectBehavior();
	},
	
	this.registerProjectBehavior = function(){

		this.$view.find('#project_levels_list input[type=radio]').each(function(){
			$(this).unbind().change(function(event){				
				var setId = $(this).parents('._WINDOW').attr("id");
				flatten = new Flatten(new Load(setId), parseInt(this.value));
				flatten.execute('json', function(data){
					var flattened_set = new XPAIR.Xset(data.set);
					// flattened_set.replace(setId);
					var xsetAdapter = new XPAIR.adapters.JstreeAdapter(new XPAIR.Xset(data.set));
					new XPAIR.projections.Jstree(xsetAdapter).show();				
				});
			})
		});
	},
	
	this.replace = function(setId){
		$("#" + setId).replaceWith(this.$view);
	},
	
	this.init_pagination_list = function(){
		first_page = this.$view.find(".pagination").children()[0];
		for(var i=2; i <= this.data.pages_count; i++){
			page_view = $(first_page).clone();
			$(page_view).find("a").text(i);
			this.$view.find(".pagination").append(page_view);
		}
		this.$view.find(".pagination li a").click(function(e){
			this_set.renderPage( parseInt($(this).text()));
			this_set.$view.find(".pagination li").removeClass("pg_active")
			$(this).parents("li").addClass("pg_active");
		});

	},
	
	this.renderPage = function(page){
		XPAIR.AjaxHelper.get("/session/render_page.json?set=" + this.getId() + "&page=" + page, "json", function(data){
			this_set.data.extension = data.extension;
			this_set.previousPage = this_set.page;
			this_set.page = page;
			this_set.notify(data.set, "pageChange");
		});
	},
	this.project = function(relation){
		new Project(new Load(this.getId()), relation).execute("json", function(data){
			this_set.data.extension = data.set.extension;
			this_set.notify(data.set);
		});

	},
	this.createEmptyView = function(){
		this.$view = $("#setViewTemplate").clone();
		this.$view.attr({
			"id": data.id,
			"exp": "Xset.load('"+data.id+"')",
		});
		

		this.$view.find("#size").html(data.size + " Items");
		
		first_level = this.$view.find(".levels_list").children()[0]
		for(var i=1; i < data.levels; i++){
			level_view = $(first_level).clone()
			level_view.find("label").html("<input type=\"radio\" name=\"filterradio\" class=\"param\" param=\"filter\" param_value=\"equals\" value=\""+(i+1)+"\"> Level" + (i+1));
			this.$view.find(".levels_list").append(level_view);
		}
		this.$view.find("#project_button").click(function(){


			var relation = $(".SELECTED").attr("item");
			this_set.project(relation);
		
		});
		this.$view.find('._show').hide();

		this.init_pagination_list();
		
		if($('#exploration_area').find('.set').length > 0) {
		
			this.$view.insertBefore($('#exploration_area').find('.set').first());
					
		} else {
			$("#exploration_area").append(this.$view);	
					
		}

		register_ui_behaviour();


		this.registerProjectBehavior()

		return this.$view;
	},
	
	this.getItem = function(itemId){
		var result = null;
		for (var i in this.data.extension){
			var item = this.data.extension[i];
			if(item.id == itemId){
				return item;
			} else {
				result = this.deepSearch(item, itemId);
				if(result != null){
					return result;
				}
			}
		}
		return result;
	},
	this.getCurrentPage = function(){
		return this.page;
	},
	this.getPreviousPage = function(){
		return this.previousPage;
	},
    this.deepSearch = function(json, itemId) {
		
        var k1 = Object.keys(json).sort();

        if (k1.length == 0) return null;
		for(var i in k1) {
			if(typeof json[k1[i]] == "object"){
				if(json[k1[i]].id == itemId){
					return json[k1[i]];
				}
				return this.deepSearch(json[k1[i]], itemId)
			}
		}
		return null;
	},
	this.getResultedFrom = function(){
		
		if(this.generatedByOperation){
			var inputSets = []
			this.generatedByOperation.getInputSets(inputSets);
			return inputSets;
		}
		return null;
	},
	this.getItemsArea = function(){
		return this.$view.find("._items_area");
	},
	
	this.getItem = function(itemId){
		return this.itemsHash.get(itemId);	
	},
	this.getId = function(){
		return this.data.id;
	},
	this.getExtension = function(){
		return this.data.extension;
	},
	XPAIR.currentSession.addSet(this);
	
	this.getIntention = function(){
		if(this.generatedByOperation){
			var operationsString = "";
			var expression = this.generatedByOperation.getExpression();
			if(expression.indexOf("union") >= 0){
				operationsString = "Union";
			} else if(expression.indexOf("intersec") >= 0){
				operationsString = "Intersection";
			} else if(expression.indexOf("dif") >= 0){
				operationsStringArray = "Diff";
			} else {
				var operationsStringArray = this.generatedByOperation.getExpression().split(".");
			
			
				for(var i = 2; i < operationsStringArray.length; i++){
					operationsString += operationsStringArray[i] + ".";
				}				
			}
			
			return operationsString;
		} else {
			if(intention){
				return this.intention;
			} else {
				return "Xset " + XPAIR.currentSession.getSetIndex(this);
			}
			
		}
		 
	};
	
}

XPAIR.Session = function(){
	this.projections = new Hashtable();
	this.sets = new Hashtable();
	this.setIndex = new Hashtable();
	this.index = 1;
	this.addProjection = function(setId, projection){
		if (!this.projections.containsKey(setId)){
			this.projections.put(setId, []);
		}
		this.projections.get(setId).push(projection);
	},
	this.addSet = function(xset){
		this.sets.put(xset.getId(), xset);
		this.setIndex.put(xset.getId(), this.index);
		this.index++;
	},
	this.getSet = function(xsetId){
		if (this.sets.containsKey(xsetId)){
			return this.sets.get(xsetId);
		}
		return null;
		
	},
	this.getSetIndex = function(xset){
		return this.setIndex.get(xset.getId());
	},
	this.getProjections = function(setId){
		if(this.projections.containsKey(setId)){
			return this.projections.get(setId);
		}
		return [];
		
	},
	this.allProjections = function(){
		var projections = [];
		for(var i in this.projections.values()){
			var setProjections = this.projections.values()[i];
			for(var j in setProjections){
				projections.push(setProjections[j]);
			}
		}
		return projections;
	}
}

XPAIR.currentSession = XPAIR.currentSession || new XPAIR.Session();

