var XPLAIN = XPLAIN || {}
function Item(itemObj){
	this.itemObj = itemObj;
	this.text = itemObj.text;
	this.id = itemObj.item
	this.getExpression = function(){

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
function Operation(inputDependencies, isVisual){
	if (inputDependencies && inputDependencies.constructor.name != "Array"){
		inputDependencies = [inputDependencies];
	}
	this.input = inputDependencies;
	this.isVisual = isVisual || false;

};

Operation.prototype = {
	input: [],
	errorMessages: [],
	isVisual: null,
	name: function(){
		
	},
	addErrorMessage: function(errorMessage){
		this.errorMessages.push(errorMessage);
	},
	getErrorMessages: function(){
		return this.errorMessages;
	},
	getDependencies: function(){
		inputSets = [];
		for (i in this.input){
			if (this.input[i] instanceof Operation){
				inputSets.concat(this.input[i].getInputChain());
			}
		}
		return inputSets;
	},
	generateParamsExpr: function(){
		paramsExpr = ""
		var that = this;
		jQuery.each(this.functionParams, function(paramName, paramValues){
		

			paramsExpr += paramName + ": ";
		
			paramsExpr += that.convertParamValues(paramValues)
			paramsExpr += ",";

		});
		return paramsExpr;
	
	},
	convertParamValues: function(value){
		expr = "";
		debugger;
		if(value.constructor.name == "Array"){

			 expr += "[" + value.map(function(v){
				if(v.constructor.name == "Array"){
					return "[" + this.convertParamValues(v) + "]";
				} else {
					return v.getExpression();
				}
			}).join(", ");
			expr += "]"

		} else{
			expr = value.getExpression();
		}
		return expr;
	},
	
	execute: function(format, successFunction, failure){
		var that = this
		debugger;
		if(this.validate()){
		
			XPLAIN.AjaxHelper.execute(this.getExpression(), successFunction || function(data){
				XPLAIN.activeWorkspaceState.addSetFromJson(data.set);
			});		
		} else {
			for (var i in this.errorMessages){
				alert(this.errorMessages[i]);

			}
			failure();
			return false;
		}
		return true;
	},
	
};

function Pivot(inputDependencies, isVisual) {	
	Operation.call(this, inputDependencies, isVisual);
	
	this.isPath = false;
	this.relations = [];
	this.isForward = true;
	this.limit = null;
	

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
				this.isForward = false;
			}
		}
	},
	this.addRelation = function(relation){
		this.relations.push(relation);
		if(relation.inverse){
			this.isForward = false;
		}
	},
		
	//private
	//TODO implement validation
	this.validate = function() {
		
		if (!this.input){
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
		relation_expr = "[" + this.relations.map(function(r){return r.getExpression()}).join(", ")+ "]";
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

		var setExpr = this.input[0].getExpression();
		var pivotExpr = "";
		if (this.isForward) {
			pivotExpr = "."+prefix+"pivot_forward(";
		}else {
			pivotExpr = "."+prefix+"pivot_backward(";
		}
		pivotExpr += this.getRelationExpr();

		pivotExpr += ")";
		return setExpr + pivotExpr;		
	}
};

Pivot.prototype = Object.create(Operation.prototype)

function FindRelations(inputDependencies, position, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
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

		expression = this.input[0].getExpression() + expression;
		return expression;
	},

	this.validate = function(){
		
		if (this.input) {
			return this.input[0].validate();
		} else {
			return false
		}
		
		return true;
	}
	
};
FindRelations.prototype = Object.create(Operation.prototype)


function Select(inputDependencies, selection){
	Operation.call(this, inputDependencies, false);
	
	this.selection = selection;
	
	this.getExpression = function(){
		var expression = this.input[0].getExpression() + ".select_items(["+this.selection.map(function(i){return i.getExpression()}).join(",")+"])";
		return expression;
	},
	
	this.validate = function(){
		if (this.input[0]) {
			return this.input[0].validate();
		} else {
			return false
		}
		return true;
	}
};
Select.prototype = Object.create(Operation.prototype)

function Refine(inputDependencies, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	this.filter = null;
	this.functionParams = {connector: 'AND'};
	this.connector = "AND";
	this.position = "image"
	this.page
	// this.filterParams = {};
	this.relations = [];

	this.setParams = function(params){
		var valuesArray = XPLAIN.activeWorkspaceWidget.params_hash.get("values");
		var filterParams = {};

		relations = []
		
		var that = this;
		if (params.containsKey("position")){
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
		
		return this.input[0].getExpression() + "."+prefix+"refine(position: \""+this.position+"\"){|f|f."+this.filter+"("+filterParams+")}";
	}
};
Refine.prototype = Object.create(Operation.prototype)

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

function FacetedSearch(inputDependencies, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
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
		that = this;
		refineOperations = refineExpressions.map(function(r){return new Expression(that.input[0].getExpression() + "."+r)});
		
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
	
	this.validate = function(){
		
		// if(this.facets.length == 0){
		// 	this.addErrorMessage("Please select at least one value to filter!")
		// 	return false;
		// }
		return true;
	}
	
	
};
FacetedSearch.prototype = Object.create(Operation.prototype)

function Union(inputDependencies){
	Operation.call(this, inputDependencies);
	
	this.inplace = false;
	this.getExpression = function(){
		if(this.validate()){
			var union = this.input[0].getExpression();
			for (var i=1; i < this.input.length; i++) {
				union += ".union(" +this.input[i].getExpression()+", inplace:"+this.inplace+")";
			}
		} else {
			alert("Not Valid Expression!");
		}
		return union;
	},
		
	this.validate = function(){
		
		if(this.input.length == 0){
			this.addErrorMessage("Please select at least one set to unite!");
			return false;
		}
		return true;
	}
};
Union.prototype = Object.create(Operation.prototype)

function Intersection(inputDependencies){
	Operation.call(this, inputDependencies);
	
	this.getExpression = function(){
		if (this.validate()){
			
			var union = this.input[0].getExpression();
			for(var i=1; i < this.input.length; i++) {
				union += ".intersect(" +this.input[i].getExpression()+")"
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return union;
	},
		
	this.validate = function(){
		
		if(this.input.length == 0){
			this.addErrorMessage("Please select at least one set to intersect!");
			return false;
		}
		return true;
		
	}
};
Intersection.prototype = Object.create(Operation.prototype)

function Difference(inputDependencies){
	Operation.call(this, inputDependencies);
	
	this.getExpression = function(){
		if(this.validate()){
			var diff = this.input[0].getExpression();
			for (var i=1; i < this.input.length; i++) {
				diff += ".diff(" +this.input[i].getExpression()+")"
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return diff;
	},
	this.validate = function(){
		
		if(this.input.length == 0){
			this.addErrorMessage("Please select at least one set to diff!");
			return false;
		}
		return true;
		
	}
};
Difference.prototype = Object.create(Operation.prototype)

function Join(inputDependencies){
	Operation.call(this, inputDependencies, isVisual);
	this.inplace = false;
	this.getExpression = function(){
		if(this.validate()){
			var join = this.input[0].getExpression();
			for(var i=1; i < this.input.length; i++) {
				join += ".join(" +this.input[i].getExpression()+", inplace:"+this.inplace+")";
			}			
		} else {
			alert("Not Valid Expression!");
		}
		return join;
	},
		
	this.validate = function(){
		
		if (this.input.length == 0){
			this.addErrorMessage("Please select at least one set to join!");
			return false;
		}
		return true;
	}
};
Join.prototype = Object.create(Operation.prototype)


//TODO include a param that is the list of params for the chosen map function
function Map(inputDependencies, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	if (!level){
		var level = 1;
	}
	
	this.mapFunction = null;
	
	this.setFunction = function(mapFunction){
		this.mapFunction = mapFunction;
	},
	
	this.setFunctionParams = function(mapFunctionMaps){
		this.functionParams = mapFunctionMaps;
	},
	
	this.getExpression = function(){
		if(this.validate()){
			
			var expression = this.input[0].getExpression();
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
		
		if(!this.mapFunction){
			this.addErrorMessage("Please select a mapping function to apply!");
			return false;
		}
		return true;
		
	}	
};
Map.prototype = Object.create(Operation.prototype)

function Group(inputDependencies, level, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	if (!level){
		var level = 1;
	}
	
	this.imageSetExpression = null;
	this.setParams = function(params){
		groupParams = {}
		
		if (params.containsKey("groupingFunction")){
			this.setFunction(params.get("groupingFunction"));
		}
		
		if ((this.groupFunction == "by_relation") || (this.groupFunction == "by_domain")){
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
				if (paramValues.length > 0){
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
		
		if(!this.input[0]){
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
		
		var groupExpr = this.input[0].getExpression() + ".group";
		if(this.imageSetExpression){
			groupExpr += "(image_set: " + this.imageSetExpression + ")"
		}
		groupExpr += "{|gf|gf."+this.groupFunction+"("+groupParamsExp+")}";
		return groupExpr;
	}
}
Group.prototype = Object.create(Operation.prototype)

function Rank(inputDependencies, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
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
		
		if (!this.input){
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
			var constructor = "";
			if(this.order){
				constructor = "{order: '" + this.order + "'";
			}
			constructor += ", position: '" + this.position + "'}";
		
			return this.input[0].getExpression() + ".rank("+constructor+"){|gf|gf."+this.rankFunction+"("+rankParamsExp+")}";
			
		} else {
			alert("Invalid expression!");
		}
	}
}
Rank.prototype = Object.create(Operation.prototype)

function Load(setId){
	this.setId = setId;
	this.getExpression = function(){
		return "Xset.load('"+this.setId.replace("#", "%23")+"')";
	},
	this.validate = function(){
		return true;	
	}
}
Load.prototype = Object.create(Operation.prototype)

function Flatten(inputDependencies, position, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	this.position = position || "image";
	this.getExpression = function(){
		var prefix = "";
		if(this.isVisual){
			prefix = "v_"
		}
		debugger;
		return this.input[0].getExpression() + "."+prefix+"flatten(position: '"+this.position+"')"
	},
	this.validate = function(){
		return true;
	}
}
Flatten.prototype = Object.create(Operation.prototype)

function Expression(expression){
	this.expression = expression
	this.getExpression = function(){ return this.expression;},
	this.validate = function(){
		return true;
	}
}
Expression.prototype = Object.create(Operation.prototype)

function Project(inputDependencies, relation){
	Operation.call(this, inputDependencies, true);
	
	this.relation = relation;
	this.getExpression = function(){
		return this.input[0].getExpression() + ".project(SchemaRelation.new('" + this.relation.replace("#", "%23") + "'))"
	},
	this.validate = function(){
		return true;
	}
	
}
Project.prototype = Object.create(Operation.prototype)
