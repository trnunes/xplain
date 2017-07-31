
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

			 expr += "[" + value.map(function(v){
				if(v.constructor.name == "Array"){
					return "[" + XPAIR.convertParamValues(v) + "]";
				} else {
					return XPAIR.getItemExpression(v);
				}
			}).join(", ");
			expr += "]"

		} else{
			expr = XPAIR.getItemExpression(value);
		}
		return expr;
	},
	
	getItemExpression: function(paramValue){
		var expr = "";
		debugger;
		if(paramValue.getExpression){
			
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
	},
		
}

/**
Exploration Model Classes
**/
function Item(itemObj){
	this.itemObj = itemObj;
	this.text = itemObj.text;
	this.id = itemObj.item
	this.getExpression = function(){
		debugger;
		if(itemObj.expression){
			return itemObj.expression;
		}
		var expr = itemObj.item_type + ".new(\""+ itemObj.item +"\"";
		if(itemObj.inverse != null){
			expr += ", " + itemObj.inverse;
		}
		
		if(itemObj.datatype != null){
			expr += ", \"" + itemObj.datatype  + "\"";
		}
		expr += ")";
		return expr.replace(/#/, "%23");
	}
};

function PathRelation(relations){
	this.relations = relations;
	this.id = relations.map(function(r){ return r.id}).join(" , ");
	this.getExpression = function(){
		var exp = this.relations.map(function(relation){return relation.getExpression()}).join(", ");
		return "PathRelation.new(["+exp+"])";
	}
};


function Relation(data){
	this.data = data;
	this.id = data.item;
	this.getExpression = function(){
		var exp = data.item_type + ".new(\"" +data.item + "\"";
		if(data.inverse != null){
			exp += ", " + data.inverse;
		}		
		exp += ")";
		return exp;
	}
};

function XsetExpr(setId){
	this.id = setId;
	
	this.getExpression = function(){
		var expr = "Xset.load('" + this.id.replace(/#/, "%23") + "')";
		return expr;
	}
	
};

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


Operation.prototype.execute = function(format, successFunction, failure){
	var that = this
	debugger;
	if(this.validate()){
		
		XPAIR.AjaxHelper.execute(this.getExpression(), successFunction || function(data){
			debugger;
			var xsetAdapter = new XPAIR.adapters.JstreeAdapter(new XPAIR.Xset(data.set, that));
			new XPAIR.projections.Jstree(xsetAdapter).init();
		}, format, this.page);		
	} else {
		for (var i in this.errorMessages){
			alert(this.errorMessages[i]);

		}
		failure();
		this.clearMessages();
		return false;
	}
	return true;
		
	
};

function Pivot(inputFunction, isVisual) {	
	
	this.isVisual = isVisual || false;
	
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
				this.path.splice(i, 1);
			}			
		} else {
			index = this.getMultipleRelationIndex(relation);
			this.relations.splice(index, 1);
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

		relation_expr = "[" + relations.map(function(r){return r.getExpression()}).join(", ")+ "]";
		
		
		if(this.limit){
			relation_expr += ", limit: " + this.limit
		}
		return "relations: " + relation_expr;
	},
	
	this.getExpression = function(){
		
		var prefix = "";
		if(this.isVisual){
			prefix = "v_";
		}

		var setExpr = this.inputFunction.getExpression();
		var pivotExpr = "";
		if (this.isForward) {
			pivotExpr = "."+prefix+"pivot_forward(";
		}else {
			pivotExpr = "."+prefix+"pivot_backward(";
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

function FindRelations(inputFunction, position, isVisual){
	this.isVisual = isVisual || false;
	this.inputFunction = inputFunction;
	this.position = position || "image";

	this.getExpression = function(){
		var prefix = "";
		if(this.isVisual){
			prefix = "v_";
		}
	
		var expression = "."+prefix+"relations";
		
		if(this.direction == "forward"){
			expression = ".forward_relations"
		}
		expression += "(limit: 25, position: '" +this.position+"')"

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
		
		var expression = this.inputFunction.getExpression() + ".select_items(["+this.selection.map(function(i){return i.getExpression()}).join(",")+"])";
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

function Refine(inputFunction, isVisual){
	this.isVisual = isVisual || false
	this.inputFunction = inputFunction;
	this.params = parameters;
	this.filter = null;
	this.functionParams = {connector: 'AND'};
	this.connector = "AND";
	this.position = "image"
	this.page
	// this.filterParams = {};
	this.relations = [];

	this.setParams = function(params){
		var valuesArray = params.get("values");
		var filterParams = {};

		relations = []
		
		var that = this;
		if(params.containsKey("position")){
			this.position = params["position"]
		}
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
		this.filter = "relation_compare";
		if((relations.length > 0) && (relations[0].constructor.name == "Operation")){
			this.filter = "compare";
		}
		
		this.functionParams.relations = [relations];
		
		this.functionParams.restrictions = restrictions
	},
	this.keywordMatch = function(keywords){
		this.filter = "keyword_match";
		this.functionParams.keywords = keywords;
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
		var prefix = "";
		if(this.isVisual){
			prefix = "v_";
		}
		
		var filterParams = this.generateParamsExpr();		
		
		return inputFunction.getExpression() + "."+prefix+"refine(position: \""+this.position+"\"){|f|f."+this.filter+"("+filterParams+")}";
	}
};
Refine.prototype = new Operation();

function Restriction(operator, value, connector){
	this.operator = operator;
	this.value = value;
	this.connector = connector;
	
	this.getComparatorExp = function(){
		var comparatorExp = "f.op."
		switch(this.operator){
		case "=":
			comparatorExp += "equal";
			break;
		case "<":
			comparatorExp += "less_than";
			break;
			
		case "<=":
			comparatorExp += "less_than_equal";
			break;
			
		case ">":
			comparatorExp += "greater_than";
			break;
			
		case ">=":
			comparatorExp += "greater_than_equal";
			break;
			
		default:
			comparatorExp += this.operator;
		}
		return comparatorExp;
	},
	
	this.getExpression = function(){
		var expr = this.getComparatorExp();
		expr += "(" + this.value.getExpression() + ")";
		return expr;
	}
	
	
};

function RelationRestriction(relation, operator, value, connector){
	this.relation = relation;
	this.restrictions = [];
	this.connector = connector || "AND";
		
	if(operator && value){
		this.addRestriction(operator, value)
	}

	this.addRestriction = function(operator, value){
		var already_added = false
		for(var i in this.restrictions){
			if(this.restrictions[i].operator == operator && this.restrictions[i].value.getExpression() == value.getExpression()){
				already_added = true;
			}
		}
		if(!already_added){
			this.restrictions.push({operator: operator, value: value})
		}
		
	},
	this.removeRestriction = function(operator, valueExpression){
		for(var i in this.restrictions){
			debugger;
			if(this.restrictions[i].operator == operator && this.restrictions[i].value.getExpression() == valueExpression){
				this.restrictions.splice(i, 1);
			}
		}
	},
	
	this.getExpression = function(){
		var restrictionExpr = ""
		restrictionExpr = this.restrictions.map(function(restrictionClause){
			
			return "['"+restrictionClause.operator+ "', " + restrictionClause.value.getExpression()+"]"
		}).join(", ");
		return restrictionExpr
	}
};

function CompositeRestrictionAnd(){
	this.restrictions = []
	
	this.addRestriction = function(restriction){
		
	}
};

function FacetedSearch(inputFunction, isVisual){
	this.isVisual = isVisual || false;
	this.inputFunction = inputFunction;
	this.facets = [];
	this.connector = "AND";
	this.simpleRestrictionsHash = new Hashtable();
	this.restrictionsByRelationHash = new Hashtable();
	this.position = "image";
	
	this.isEmpty = function(){
		return (this.simpleRestrictionsHash.isEmpty() && this.restrictionsByRelationHash.isEmpty());
	},
	
	this.addRestriction = function(restriction){
		debugger;
		if(restriction.constructor.name == "RelationRestriction"){
			if(!this.restrictionsByRelationHash.containsKey(restriction.relation.getExpression())){
				this.restrictionsByRelationHash.put(restriction.relation.getExpression(), restriction);
			}
			relationRestriction = this.restrictionsByRelationHash.get(restriction.relation.getExpression());
			relationRestriction.addRestriction(restriction.operator, restriction.value);
			relationRestriction.connector = restriction.connector;
			
		} else {
			if(!this.simpleRestrictionsHash.containsKey(restriction.getExpression())){
				this.simpleRestrictionsHash.put(restriction.getExpression(), restriction);
				this.simpleRestrictionsHash.values().forEach(function(addedRes){addedRes.connector = restriction.connector})
			}
		}
	},
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
		var html = "";
		var that = this;
		for(var i in this.restrictionsByRelationHash.keys()){
			relationExpr = this.restrictionsByRelationHash.keys()[i];
			facet = this.restrictionsByRelationHash.get(relationExpr);
			relationExpr = facet.relation.id
			facetHtml = facet.restrictions.map(function(restriction){
				var restriction_div = "";
				restriction_div += "<td><span>" + relationExpr + " "+ restriction.operator + " " + restriction.value.text + "<span class='close' operator= \""+restriction.operator+"\" facet='"+facet.relation.getExpression()+"' facet_value='"+restriction.value.getExpression()+"'>x</span></span>" + "</td>";
				debugger;
				return restriction_div;
			}).join(" <td class=\"filter_connector\"><span >" + facet.connector + " </span></td>");
			html += "<tr>" + facetHtml + "</tr>";
		}
		
		var simpleResTableCols = this.simpleRestrictionsHash.values().map(function(restriction){
			var restriction_div = "";
			restriction_div += "<td><span>" + that.position + " "+ restriction.operator + " " + restriction.value.text + "<span class='close' operator=\""+restriction.operator+"\" facet_value='"+restriction.value.getExpression()+"'>x</span></span>" + "</td>";
			debugger;
			return restriction_div
		});
		var simpleResHtml =  ""
		if(simpleResTableCols.length > 0){
			simpleResHtml = simpleResTableCols.join(" <td class=\"filter_connector\"><span >" + this.simpleRestrictionsHash.values()[0].connector + " </span></td>");;
		}
		html += "<tr>" + simpleResHtml + "</tr>";
		
		return html;
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
	this.removeRelationRestriction = function(relationToRemove, operatorToRemove, valueToRemove){
		restriction = this.restrictionsByRelationHash.get(relationToRemove);
		restriction.removeRestriction(operatorToRemove, valueToRemove);
		if (restriction.restrictions.length == 0){
			this.restrictionsByRelationHash.remove(relationToRemove);
		}
	},
	this.removeSimpleRestriction = function(operatorToRemove, valueToRemove){
		restriction = new Restriction(operatorToRemove, new Item({expression: valueToRemove}));
		
		this.simpleRestrictionsHash.remove(restriction.getExpression());
	},
	
	this.getExpression = function(){
		var prefix = "";
		if(this.isVisual){
			prefix = "v_";
		}
		
		var expr = ""
		var connector = "AND"
		var simpleRestrictionExpr = this.simpleRestrictionsHash.values().map(function(r){
			connector = r.connector || "AND"
			return r.getExpression();
		}).join(", ");
		
		refineExpressions = [];
		if(simpleRestrictionExpr != ""){
			simpleRestrictionExpr = prefix + "refine(position: '"+this.position+"'){|f| f.compare(connector: \""+connector+"\", restrictions: ["+simpleRestrictionExpr+"])}"
			refineExpressions.push(simpleRestrictionExpr);
		}
		
		for( var i in this.restrictionsByRelationHash.keys()){
			var key = this.restrictionsByRelationHash.keys()[i];
			debugger;
			expression = this.restrictionsByRelationHash.get(key).getExpression();
			connector = this.restrictionsByRelationHash.get(key).connector || "AND"
			refineExpression = prefix + "refine(position: '"+this.position+"'){|f| f.relation_compare(relations: ["+key+"], connector: \""+connector+"\", restrictions: ["+expression+"])}"
			refineExpressions.push(refineExpression);
		}
		refineOperations = refineExpressions.map(function(r){return new Expression(inputFunction.getExpression() + "."+r)});
		
		var facetedSearch = refineOperations[0];

		if(refineExpressions.length > 1){
			if(this.connector == "AND"){
				
				facetedSearch = new Intersection(refineOperations);
			} else {
				facetedSearch = new Union(refineOperations);
			}
		}

		return facetedSearch.getExpression();
		
	},
	// this.getExpression = function(){
	// 	var refineOperations = [];
	// 	var facetedSearch = null;
	//
	// 	for(var i in this.facets){
	// 		var facet = this.facets[i];
	// 		var relation = facet[0];
	// 		if(relation.constructor.name != "Array"){
	// 			relation = [relation]
	// 		}
	//
	// 		var refineOp = new Refine(this.inputFunction);
	// 		debugger;
	// 		refineOp.compare(relation, [facet[1]]);
	// 		if(facet[2]){
	// 			refineOp.setConnector(facet[2]);
	// 		}
	//
	// 		refineOperations.push(refineOp);
	// 	}
	//
	// 	if(refineOperations.length > 1){
	// 		if(this.connector == "AND"){
	// 			facetedSearch = new Intersection(refineOperations);
	// 		} else {
	// 			facetedSearch = new Union(refineOperations);
	// 		}
	// 	} else {
	// 		facetedSearch = refineOperations[0];
	// 		facetedSearch.setConnector(this.connector);
	// 	}
	//
	// 	return facetedSearch.getExpression();
	// },
	
	this.validate = function(){
		this.clearMessages();
		// if(this.facets.length == 0){
		// 	this.addErrorMessage("Please select at least one value to filter!")
		// 	return false;
		// }
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
	this.inputFunction = functions;
	
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
		if(this.inputFunction.length == 0){
			this.addErrorMessage("Please select at least one set to intersect!");
			return false;
		}
		return true;
		
	}
};
Intersection.prototype = new Operation();

function Difference(functions){
	this.inputFunction = functions;
	
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
		if(this.inputFunction.length == 0){
			this.addErrorMessage("Please select at least one set to diff!");
			return false;
		}
		return true;
		
	}
};
Difference.prototype = new Operation();

function Join(functions){
	this.inputFunction = functions;
	this.inplace = false;
	this.getExpression = function(){
		if(this.validate()){
			var join = this.inputFunction[0].getExpression();
			for(var i=1; i < this.inputFunction.length; i++) {
				join += ".join(" +this.inputFunction[i].getExpression()+", inplace:"+this.inplace+")";
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return join;
	},
		
	this.validate = function(){
		this.clearMessages();
		if(this.inputFunction.length == 0){
			this.addErrorMessage("Please select at least one set to join!");
			return false;
		}
		return true;
	}
};
Join.prototype = new Operation();


//TODO include a param that is the list of params for the chosen map function
function Map(inputFunction, isVisual){
	this.isVisual = isVisual || false
	if(!level){
		var level = 1;
	}
	this.inputFunction = inputFunction;
	this.mapFunction = null;

	
	
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
			expression += ".map(){|f| f."+functionExpression+"}";
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
	
	this.imageSetExpression = null;
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
		
		var groupExpr = inputFunction.getExpression() + ".group";
		if(this.imageSetExpression){
			groupExpr += "(image_set: " + this.imageSetExpression + ")"
		}
		groupExpr += "{|gf|gf."+this.groupFunction+"("+groupParamsExp+")}";
		return groupExpr;
	}
}
Group.prototype = new Operation();

function Rank(inputFunction){
	this.inputFunction = inputFunction;
	this.rankFunction = null;
	this.functionParams = null;
	this.order = null;
	this.position = "image"
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
			if(!this.functionParams.relation){
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
				constructor = "{order: '" + this.order + "'";
			}
			constructor += ", position: '" + this.position + "'}"
		
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
function Flatten(inputFunction, position, isVisual){
	this.isVisual = isVisual || false;
	this.inputFunction = inputFunction;
	this.position = position || "image";
	this.getExpression = function(){
		var prefix = "";
		if(this.isVisual){
			prefix = "v_"
		}
		return this.inputFunction.getExpression() + "."+prefix+"flatten(position: '"+this.position+"')"
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
		return this.inputFunction.getExpression() + ".project(SchemaRelation.new('" + this.relation.replace("#", "%23") + "'))"
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
	this.isGroupedSet = function(){
		if(!this.isEmpty()){
			return this.data.extension[0].children;
		}
		return false;
	},
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
	
	this.getImage = function(){
		var items = new Hashtable();
		debugger;
		this.data.extension.forEach(function(item){
			this_set.getLeafNodes(items, item);
		});
		return items.values();
	}
	this.getLeafNodes = function(leafNodes, obj){
		console.log(obj.children)
	    if(obj.children){
	        obj.children.forEach(function(child){this_set.getLeafNodes(leafNodes,child)});
	    } else{
			console.log("leaf: ", obj);
	        leafNodes.put(obj.id, obj);
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
			this_set.data.extension = data.set.extension;
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
	this.domain = function(callback){
		XPAIR.AjaxHelper.get("/session/domain.json?set=" + this.getId(), "json", function(data){
			callback(data);
		});
		
	}
	this.createEmptyView = function(){
		this.$view = $("#setViewTemplate").clone();
		this.$view.find('#windowtitlemin').hide();
		this.$view.attr({
			"id": data.id,
			"exp": "Xset.load('"+data.id+"')",
		});
		

		this.$view.find("#size").html(data.size + " Items");
		this.$view.find("#set_title").html(data.title);
		this.$view.find("#titlemin").html(data.title);
		this.$view.find("#set_title").click(function(e){
			e.stopPropagation();
			this_set.$view.find("#set_title").html("<input type=\"text\" id=\"set_title_input\">");
			this_set.$view.find("#set_title_input").attr("value", this_set.data.title)
			this_set.$view.find("#set_title_input").bind("enterKey",function(e){
				
				this_set.$view.find("#set_title").html($(this).val());
				this_set.$view.find("#titlemin").html($(this).val())
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

			op =  new Flatten(new FindRelations(new Load(this_set.getId())));
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
		debugger;

		register_ui_behaviour();


		this.registerProjectBehavior()
		

		// $("#" + this.getId()).tooltip({title: this.getTitle()});

		// $("[data-toggle='tooltip']").tooltip('destroy');
		// $("[data-toggle='tooltip']").tooltip();
		// $("#" + this.getId()).attr('data-original-title', this.getTitle())
		
		

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
		XPAIR.AjaxHelper.get("/session/update_title?set="+ this.getId()+ "&title=" + title, "json", function(data){});
		$("#" + this.getId()).attr("data-original-title", title);
		return this.data.title;
	},
	this.getExtension = function(){
		return this.data.extension;
	},
	this.isEmpty = function(){
		return (this.data.extension.length == 0)
	},
	XPAIR.currentSession.addSet(this);
	
	this.getIntention = function(){
		 return this.data.intention
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

