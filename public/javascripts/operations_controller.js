
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
	convertParamValues: function(value){
		expr = "";
		debugger;
		if(value.constructor.name == "Array"){

			 expr += value.map(function(v){ 
				 
				if(v.constructor.name == "Array"){
					return "[" + XPAIR.convertParamValues(v) + "]";
				} else {
					return XPAIR.getItemExpression(v);
				}
			}).join(", ");

		} else{
			expr = XPAIR.getItemExpression(value);
		}
		return expr;
	},
	
	getItemExpression: function(paramValue){
		var expr = "";
		
		if(paramValue.constructor.name == "Operation"){
			
			expr = paramValue.getExpression(); 
			
		} else if((typeof paramValue == "object")) {

			if(paramValue.item_type == "Xpair::Literal" && paramValue.datatype){
				expr = paramValue.item_type + ".new('"+paramValue.item.replace("#", "%23")+"','"+ paramValue.datatype.replace("#", "%23") +"')";
			} else{
				expr = paramValue.item_type + ".new('"+paramValue.item.replace("#", "%23")+"')";
			}
			
		} else {
			expr = "'" + paramValue + "'";
		}
		return expr;
		
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
		
		paramsExpr += XPAIR.convertParamValues(paramValues)
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
	this.isPath = false;
	this.path = [];
	this.relations = [];
	this.isForward = true;
	this.limit = null;
	this.inputFunction = inputFunction;

	this.setParams = function(params){

		if(params.containsKey("path")){
			this.isPath = true;
		}
		
		if(params.containsKey("relations")){
			var targetRelations = params.get("relations");
		}
		

		for(var i=0; i< targetRelations.length; i++) {
			this.addRelation(targetRelations[i]);
			if(targetRelations[i].inverse){
				this.backward(true);
			}
		}
	},
	this.backward = function(boolean){
		this.isForward = !boolean;
	},
	this.appendToPath = function(relation){
		this.path.push(relation);
		if(relation.inverse){
			this.backward(true);
		}
	},
	this.insertToPath = function(relationId){
		this.path.unshift(relationId);
	},
	this.getPath = function(){
		return this.path;
	},
	this.addRelation = function(relation){
		this.relations.push(relation);
		if(relation.inverse){
			this.backward(true);
		}
	},
	this.containsRelation = function(relation){
		return (this.getPathRelationIndex(relation) >= 0 || this.getMultipleRelationIndex(relation) >= 0);
	},
	
	this.getPathRelationIndex = function(relation){
		for(var i in this.path){
			if((this.path[i].item == relation.item) && (this.path[i].inverse == relation.inverse)){
				return i;
			}	
		}
		return -1;
	},
	
	this.getMultipleRelationIndex = function(relation){
		for(var i in this.relations){
			if((this.relations[i].item == relation.item) && (this.relations[i].inverse == relation.inverse)){
				return i;
			}
		}
		return -1
	},
	
	this.removeRelation = function(relation){
		var index = this.getPathRelationIndex(relation);
		if (index >= 0){
			for(var i = 0; i <= index; i++) {
				this.path.splice(i);
			}			
		} else {
			index = this.getMultipleRelationIndex(relation);
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
		debugger;
		if(relations.length > 1){
			relation_expr = "relations: [" + relations.map(function(r){return "'" + encodeURI(r.item).replace(/#/g, '%23') + "'"}).join() + "]";
		} else {
			relation_expr = "relations: '" + encodeURI(relations[0].item).replace(/#/g, '%23') + "'";
		}
		
		if (this.isPath) {
			relation_expr += ", path: true";
		}
		
		if(this.limit){
			relation_expr += ", limit: " + this.limit
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

function PivotGroup(inputFunction){
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
Pivot.prototype = new Operation();

function FindRelations(inputFunction, direction){
	this.inputFunction = inputFunction;
	this.direction = direction;

	this.getExpression = function(){
		var expression = ".relations";
		debugger;
		if(this.direction == "forward"){
			expression = ".forward_relations"
		}
		expression += "(limit: 25)"

		expression = this.inputFunction.getExpression() + expression;
		return expression;
	},
	this.type = function(){
		return "Relations";
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
		var operatorValues = []
		for(var i in values){
			operatorValues.push(["=", values[i]]);
		}
		this.compare(relations, operatorValues);
		this.filter = "equals"
	},
	this.compare = function(relations, restrictions){
		this.filter = "compare";
		if((relations.length > 0) && (relations[0].constructor.name == "Operation")){
			this.filter = "image_equals";
		}
		
		this.functionParams.relations = [relations];
		
		this.functionParams.restrictions = restrictions
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
	
	this.addFacet = function(relation, operator, value, connector){
		
		var added = false;

		for(var i in this.facets){
			
			if(this.equalFacets(this.facets[i][0], relation)){
				
				this.facets[i][1].push([operator, value]);
				
				if(connector){
					this.facets[i].push(connector);
				} else {
					this.facets[i].push("AND");
				}
				
				
				added = true;
			}
			
		}
		
		if(!added){
			this.facets.push([relation, [[operator, value]]])
		}
		
	},
	
	this.toHtml = function(){
		return this.facets.map(function(facet){
			var html = "";
			var restrictionStr = "";
			relation = facet[0];
			restrictions = facet[1];
			
			if(!relation.constructor.name == "Array"){
				relation = [relation];
			}
			var relationStr = relation.map(function(relation){return relation.item;}).join(" &rarr; ");
			relationStr += " "
			restrictionStr = relationStr;

			html = restrictions.map(function(restriction){
				var restriction_div = "";
				restriction_div += "<td><span>" + relationStr + " "+ restriction[0] + " " + restriction[1].item + "<span class='close' facet=\""+relationStr+"\" facet_value=\""+restriction[1].item+"\">x</span></span>" + "</td>";
				return restriction_div
			}).join(" <td class=\"filter_connector\"><span >" + facet[2] + " </span></td>");

			
			// html += restrictions.map(function(restriction){
			// 	var restriction_div = "<div class = \"filter_div\">";
			//
			// 	restriction_div += "<span>" + relationStr + " "+ restriction[0] + " " + restriction[1].item; + "</span>";
			// 	restriction_div += "	<div style=\"float: right;\">";
			// 	restriction_div += "		 <span id='close'>x</span>"
			// 	restriction_div += "	</div>";
			// 	restriction_div += "</div>";
			// 	return restriction_div
			// }).join(" <span class=\"filter_connector\">" + facet[2] + " </span>");

			return "<tr>" + html + "</tr>";
		});
	},
	this.getComparable = function(facet){
		if(facet.constructor.name == "Operation"){
			relationComparable = facet.getExpression();
		} else if(facet.constructor.name == "Array") {
			relationComparable = facet.map(function(r){return r.item}).join();
		} else {
			relationComparable = facet.item
		}
		return relationComparable;
	},
	
	this.equalFacets = function(facet1, facet2){
		
		var relationComparable = this.getComparable(facet1);
		var relationToRemoveComparable = this.getComparable(facet2);
		return (relationComparable == relationToRemoveComparable)
	},
	this.setConnector = function(connector){
		this.connector = connector;
	},
	this.removeFacet = function(relationToRemove, operatorToRemove, valueToRemove){
		
		for (var i in this.facets){
			var relation = this.facets[i][0];
			var restrictions = this.facets[i][1];
			var index = -1
			for(var j in restrictions){
				var operator = restrictions[j][0];
				var value = restrictions[j][1];
				debugger;
				if (value.item == valueToRemove.item){
					index = j;
				}
			}

			if((this.equalFacets(relation, relationToRemove)) && (index >= 0)){
				restrictions.splice(index);
				if(restrictions.length == 0){
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
			var relation = facet[0];
			if(relation.constructor.name != "Array"){
				relation = [relation]
			} 
			
			var refineOp = new Refine(this.inputFunction);
			debugger;
			refineOp.compare(relation, [facet[1]]);
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
	this.inplace = false;
	this.getExpression = function(){
		if(this.validate()){
			var union = this.inputFunction[0].getExpression();
			for(var i=1; i < this.inputFunction.length; i++) {
				union += ".union(" +this.inputFunction[i].getExpression()+", inplace:"+this.inplace+")";
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
		
		if((this.groupFunction == "by_relation") || (this.groupFunction == "by_domain")){
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
		first_page = this.$view.find(".pagination").children()[1];
		console.log(this.data.pages_count)
		if(this.data.pages_count <= 1){
			this.$view.find(".pagination_div").remove();
		} else {
			var pagesList = []
			if(this.data.pages_count >= 5){
				for(var i=2; i<=5; i++){

					page_view = $(first_page).clone();
					$(page_view).find("a").text(i);
					if(i == 3){
						$(page_view).find("a").text("...");
					} else if(i == 4){
						$(page_view).find("a").text(this.data.pages_count - 1);
					} else if(i == 5){
						$(page_view).find("a").text(this.data.pages_count);
					}				
					pagesList.push(page_view)

				}

			} else{
				for(var i=2; i <= this.data.pages_count; i++){
					
					page_view = $(first_page).clone();
					$(page_view).find("a").text(i);
					pagesList.push(page_view);
				}				
			}
			var lastPage = first_page;
			for(var i in pagesList){
				$(pagesList[i]).insertAfter($(lastPage))
				lastPage = pagesList[i];
			}
			
			this.$view.find(".pagination li a").click(function(e){
				

				var pageNumber;
				var activePageText = $(this).parents('li').siblings('.pg_active').text();
				if($(this).attr("aria-label") == "Next"){
					pageNumber = parseInt(activePageText) + 1;
					debugger;
					if(parseInt(activePageText) == this_set.data.pages_count){
						return;
					}
					
					if($(this).parents("ul").find("li a").filter(function(){return $(this).text() == ""+pageNumber}).length == 0){
						$(this_set.$view.find(".pagination li a")[1]).html(pageNumber - 1);
						$(this_set.$view.find(".pagination li a")[2]).html(pageNumber);
					}
				}else if($(this).attr("aria-label") == "Previous"){
					debugger;
					if(parseInt(activePageText) == 1){
						return;
					}
					
					pageNumber = parseInt(activePageText) - 1
					if(pageNumber < this_set.data.pages_count - 2){
						$(this_set.$view.find(".pagination li a")[1]).html(pageNumber);
						$(this_set.$view.find(".pagination li a")[2]).html(pageNumber+1);
					}
					
				} else {
					if($(this).text() != "..."){
						activePageText = $(this).text()
						pageNumber = parseInt(activePageText);
					}
				}	

					
				this_set.renderPage(pageNumber);
				
				
				this_set.$view.find(".pagination li").removeClass("pg_active")
				$(this).parents("ul").find("li a").filter(function(){return $(this).text() == ""+pageNumber}).parents('li').addClass("pg_active")
					
			});
			$(this_set.$view.find(".pagination li")[1]).addClass("pg_active");
			
		}

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
		this.$view.find("#set_title").html(data.title);
		this.$view.find("#set_title").click(function(e){
			e.stopPropagation();
			this_set.$view.find("#set_title").html("<input type=\"text\" id=\"set_title_input\">");
			this_set.$view.find("#set_title_input").attr("value", this_set.data.title)
			this_set.$view.find("#set_title_input").bind("enterKey",function(e){
				
				this_set.$view.find("#set_title").html($(this).val());
				this_set.setTitle($(this).val());
				
			});
			this_set.$view.find("#set_title_input").focus()
			this_set.$view.find("#set_title_input").keyup(function(e){

			    if(e.keyCode == 13){
			        $(this).trigger("enterKey");
			    }
			});
		});
		
		first_level = this.$view.find(".levels_list").children()[0]
		for(var i=1; i < data.levels; i++){
			level_view = $(first_level).clone()
			level_view.find("label").html("<input type=\"radio\" name=\"filterradio\" class=\"param\" param=\"filter\" param_value=\"equals\" value=\""+(i+1)+"\"> Level" + (i+1));
			this.$view.find(".levels_list").append(level_view);
		}
		
		this.$view.find("#visualize").click(function(e){

			op =  new FindRelations(new Load(this_set.getId()), "forward");
			op.execute("json", function(data){
				debugger;
				this_set.$view.find("#properties").empty();
				for(var i in data.set.extension){
					var r = data.set.extension[i];
					if(!r.inverse){
						this_set.$view.find("#properties").append("<li><a class=\"v_property\" tabindex=\"-1\" >"+r.id+"</a></li>");
					}
					
				}
				
				this_set.$view.find(".v_property").click(function(e){
					debugger;
					var relation = this.text
					this_set.project(relation);
		
				});
				
			});
			
		});
		this.$view.find('._show').hide();

		this.init_pagination_list();
		
		if($('#exploration_area').find('.set').length > 0) {
		
			this.$view.insertBefore($('#exploration_area').find('.set').first());
					
		} else {
			this.$view.insertAfter($('#graph_view'));
					
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
	this.getTitle = function(){
		
		return this.data.title;
	},
	this.setTitle = function(title){
		XPAIR.graph.updateNodeTitle(this.data.id, title);
		this.data.title = title;
		XPAIR.AjaxHelper.get("/session/update_title?set="+ this.getId()+ "&title=" + title, "json");
		return this.data.title;
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
			if(this.intention){
				return this.intention;
			} else {
				""
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

