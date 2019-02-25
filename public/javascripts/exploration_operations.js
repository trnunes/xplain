var XPLAIN = XPLAIN || {}
function Item(itemObj){
	this.itemObj = itemObj;
	this.text = itemObj.text;
	this.id = itemObj.id;

	this.getExpression = function(){

		if(itemObj.expression){
			return itemObj.expression;
		}
		var type = ""
		debugger
		switch(itemObj.type){
			case "Xplain::Entity":
				type = "entity";
				break;
			case "Xplain::Type":
				type = "type";
				break;
			case "Xplain::Literal":
				type = "literal";
				break;
		}

		var expr = type + " \""+ itemObj.id +"\"";
		if(itemObj.inverse != null){
			expr += ", " + itemObj.inverse;
		}
		
		if(itemObj.datatype != null){
			expr += "=> \"" + itemObj.datatype  + "\"";
		}
		
		return expr.replace(/#/, "%23");
	}
};

function PathRelation(relations){
	this.relations = relations;
	this.id = relations.map(function(r){ return r.id}).join(" , ");
	this.getExpression = function(){
		var exp = this.relations.map(function(relation){return relation.getExpression()}).join(", ");
		return exp;
	}
};


function Relation(data){
	this.data = data;
	this.id = data.item;
	this.getExpression = function(){

		var exp = "\"" + data.item + "\"";
		
		if(data.inverse == "true"){
			exp = "inverse(" + exp+ ")";
		}		
		
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
	postProcessingExpression: "",

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
		
		if(this.validate()){
			debugger;
			XPLAIN.AjaxHelper.execute(this.getExpression() + ".execute" + this.postProcessingExpression, successFunction || function(data){
				XPLAIN.activeWorkspaceState.addSetFromJson(data);
			});		
		} else {
			for (var i in this.errorMessages){
				alert(this.errorMessages[i]);

			}
			failure();
			return false;
		}
		return true;
	}
	
};

Pivot = function (inputDependencies, isVisual) {	
	Operation.call(this, inputDependencies, isVisual);
	this.isPath = false;
	this.relations = [];
	this.isForward = true;
	this.limit = null;
	this.position = null;
	this.group_by_domain = false;
	this.debug = false;
	this.visual = false;
}
Pivot.prototype = Object.create(Operation.prototype);
Pivot.prototype.postProcessingExpression = "";
Pivot.prototype.setParams =  function(params){

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
}

Pivot.prototype.addRelation = function(relation){
	this.relations.push(relation);
	if(relation.inverse){
		this.isForward = false;
	}
}
		
	//private
	//TODO implement validation
Pivot.prototype.validate = function() {

	if (!this.input){
		this.addErrorMessage("You must select one of the sets in the exploration area for this operation!");
		return false;
	}

	if((this.relations.length == 0)){
		this.addErrorMessage("You must select at least one relation in the exploration area to pivot!");
		return false;
	}
	return true;

}
		
Pivot.prototype.getRelationExpr = function() {
	var relation_expr = "";
	debugger;
	relation_expr = this.relations.map(function(r){return r.getExpression()}).join(", ");

	return "relation " + relation_expr;
}
	
Pivot.prototype.getExpression = function(){

	var prefix = "";
	if(this.isVisual){
		prefix = "v_";
	}

	var setExpr = this.input[0].getExpression();
	var pivotExpr = ".pivot(";
	if (this.position) {
		pivotExpr += "level: "+this.position + ",";
	}
	if (this.limit){
		pivotExpr += " limit: " + this.limit + ",";
	}
	if (this.group_by_domain) {
		pivotExpr += " group_by_domain: true,"
	}
	if (this.debug) {
		pivotExpr += " debug: true,"
	}
	if (this.visual) {
		pivotExpr += " visual: true"
	}
	pivotExpr += ")";
	pivotExpr += "{" +this.getRelationExpr()+"}";

	return setExpr + pivotExpr;		
}

Pivot.prototype.uniq = function(){
	this.postProcessingExpression += ".uniq!.sort_asc!";
	return this;
}



function FindRelations(inputDependencies, position, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	this.position = position || "2";

	this.getExpression = function(){
		var prefix = "";
		if(this.isVisual){
			prefix = "v_";
		}
	
		var expression = "."+prefix+"relations";
		
		if(this.direction == "forward"){
			expression = ".forward_relations"
		}
		expression += "(limit: 25, level: " +this.position+")"

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
	},

	this.postProcessingExpression = function(){
		return ".uniq!";

	}
	
};
FindRelations.prototype = Object.create(Operation.prototype)


function Select(inputDependencies, selection){
	Operation.call(this, inputDependencies, false);
	
	this.selection = selection;
	
	this.getExpression = function(){
		var expression = this.input[0].getExpression() + ".nodes_select(ids: ["+this.selection.map(function(id){return "\""+id+"\""}).join(",")+"])";
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
	this.position = "2"
	this.page
	// this.filterParams = {};
	this.relations = [];

	//TODO remove this method
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
		
		return this.input[0].getExpression() + "."+prefix+"refine(level: "+this.position+"){|f|f."+this.filter+"("+filterParams+")}";
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

	//TODO replicated code with Restriction! Generalize it.
	this.getComparatorExp = function(operator){		
		switch(operator){
		case "=":
			return "equals";			
		case "<":
			return "less_than";
		case "<=":
			return "less_than_equal";
		case ">":
			return "greater_than";
		case ">=":
			return "greater_than_equal";			
		default:
			return operator;
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
		var restrictionExpr = "";
		var that = this;
		restrictionExpr = this.restrictions.map(function(restrictionClause){
			return that.getComparatorExp(restrictionClause.operator) +"{  relation "+ that.relation.getExpression() + ";" + restrictionClause.value.getExpression()+"}"
		}).join(", ");
		return restrictionExpr
	}
};


function KeywordSearch(keywords, isVisual){
	Operation.call(this, null, isVisual);
	this.keywords = keywords;
	this.getExpression = function(){
		var prefix = "";
		var expr = "Xplain::KeywordSearch.new(keyword_phrase: \""+ keywords.join(" ")+"\")";
		return expr	;
	},
	
	this.validate = function(){
		//TODO validate keyword expression
		return true;
	}


};
KeywordSearch.prototype = Object.create(Operation.prototype);

function FacetedSearch(inputDependencies, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	this.facets = [];
	this.connector = "And";
	this.simpleRestrictionsHash = new Hashtable();
	this.restrictionsByRelationHash = new Hashtable();
	this.filters = []
	this.position = "2";
	
	this.isEmpty = function(){
		return (this.simpleRestrictionsHash.isEmpty() && this.restrictionsByRelationHash.isEmpty());
	},

	this.addFilter = function(name, code){
		var filter_code = "c_filter(";
		if (name) {
			filter_code += " name: \"" + name +"\", code:";

		}
		filter_code += " '" + code + "')";
		if (this.filters.indexOf(filter_code) < 0){
			this.filters.push(filter_code);
		}

	},
	this.getComparatorExp = function(operator){		
		switch(operator){
		case "=":
			return "equals";			
		case "<":
			return "less_than";
		case "<=":
			return "less_than_equal";
		case ">":
			return "greater_than";
		case ">=":
			return "greater_than_equal";			
		default:
			return operator;
		}
	},

	this.toDSL = function(comparator, relationObj, valueObj){
		
		if (!valueObj){
			alert("You should provide at least one comparison value!");
			return;
		}

		if (!relationObj) {
			relationObj = this.input[0];
		}

		if(!comparator){
			comparator = "equals";
		} else{
			comparator = this.getComparatorExp(comparator);
		}

		var restrictionDSL = comparator + " { relation " + relationObj.getExpression() + "; " +  valueObj.getExpression() + " } ";
		return restrictionDSL;
	},
	
	this.addRestriction = function(comparator, relation, value){
		debugger

		var dslCode = this.toDSL(comparator, relation, value);
		debugger
		if (this.filters.indexOf(dslCode) < 0){
			this.filters.push(dslCode);
		}
	},
	
	this.toHtml = function(){
		var html = "";

		var c_filter_cols = this.filters.map(function(filterSpec){
			return "<td><span>" + filterSpec + "</span>"+"<span class='close filter_remove'>x</span>"+"</td>";
		}).join(" <td class=\"filter_connector\"><span >" + this.connector + "</span></td>");
		debugger;
		html += "<tr>" + c_filter_cols + "</tr>";
		return html;
	},

	this.removeFilter = function(filterCode){
		this.filters.splice(this.filters.indexOf(filterCode));
	},
	
	this.getExpression = function(){
		var prefix = "";
		var expr = ".refine";
		debugger;
		if (this.position) {			
			expr += "(level: " + this.position + ")";
		}
		if (this.isVisual){
			//TODO IMPLEMENT
		}


		expr += "{"+this.connector+"{[";

		expr += this.filters.join(", ");
		expr += "]}}";
		return this.input[0].getExpression() + expr	;
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
			var union = "";
			for (var i=0; i < this.input.length; i++) {
				union += this.input[i].getExpression()+", ";
			}
		} else {
			alert("Not Valid Expression!");
		}
		return "Xplain::Unite.new([" + union + "])";
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
		if(this.validate()){
			var intersect = "";
			for (var i=0; i < this.input.length; i++) {
				intersect += this.input[i].getExpression()+", ";
			}
		} else {
			alert("Not Valid Expression!");
		}
		return "Xplain::Intersect.new([" + intersect + "])";
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
			var diff = "";
			for (var i=0; i < this.input.length; i++) {
				diff += this.input[i].getExpression()+", ";
			}
		} else {
			alert("Not Valid Expression!");
		}
		return "Xplain::Diff.new([" + diff + "])";
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
	this.position = 0;
	
	this.mapFunction = null;
	this.relations = null;
	
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
				functionExpression += "(["+ this.functionParams.join(",")+"])";
			}
			
			expression += ".aggregate"
			if (this.position){
				expression += "(level: "+this.position+")";
			}
			expression += "{"+functionExpression;
			if (this.relations.length) {
				var relationExpr = this.relations.map(function(rel){return rel.getExpression();}).join(", ");
				expression += "{ relation " + relationExpr + "}";
			}
			expression += "}";
			debugger;
			return expression;
		}else {
			alert("Not Valid Expression!");
		}
	},
	this.validate = function(){
		//TODO implement validation
		return true;
		
	}	
};
Map.prototype = Object.create(Operation.prototype)

function Group(inputDependencies, level, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	this.params = {};
	this.limit = null;
	if (!level){
		var level = 1;
	}
	
	this.imageSetExpression = null;
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
		if(this.groupFunction == "by_image"){
			
			if (!(this.params.relations && this.params.relations.length > 0)){
				this.addErrorMessage("You must select a relation or a relation set in the exploration area!");
				return false;
			}
			
		}
		return true;
		
	},
	this.getExpression = function(){
		
		var relationExpr = this.params.functionParams.map(function(rel){return rel.getExpression();}).join(", ");
		debugger
		var groupExpr = "group(";
		if(this.limit) {
			groupExpr += "limit: " + this.limit;
		}
		groupExpr += ")";
		return this.input[0].getExpression() + ".group{"+this.params.function + "{ relation " +  relationExpr + "}}";
	}
}
Group.prototype = Object.create(Operation.prototype)

function Rank(inputDependencies, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	this.rankFunction = null;
	this.functionParams = null;
	this.order = null;
	this.position = null;
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
// 		TODO: fix validations
// 		if(!this.input){
// 			this.addErrorMessage("Please select a set to rank!");
// 			return false;
// 		}
// 		if(!this.rankFunction){
// 			this.addErrorMessage("Please select a ranking function to rank the set!");
// 			return false;
// 		}
		
// 		if(this.rankFunction == "by_relation"){
// 			if(!this.functionParams.relation){
// 				this.addErrorMessage("You must select at least one relation/relation set for ranking!");
// 				return false;
// 			}
// 		}
		return true;
	},
	this.getExpression = function(){
					
		var expression = ".rank";
		expression += "(";
		debugger
		if (this.order == "DESC") {
			expression += 'order: :desc,'
		}

		if (this.position){
			expression += " level: "+this.position;
		}
		expression += ")";
		if (this.functionParams){
			expression += "{" + this.functionParams.function;
			delete this.functionParams.function;
			
			expression += "{"
			
			jQuery.each(this.functionParams, function(paramName, paramValues){
				expression += " " + paramName;
				if (paramValues.getExpression) {
					expression += " " + paramValues.getExpression();

				} else {
					expression += " " + paramValues;
				}
				
			});
			expression += "}}";
		}

		
		return this.input[0].getExpression() + expression;
	}
}
Rank.prototype = Object.create(Operation.prototype)

function Load(setId){
	this.setId = setId;
	this.getExpression = function(){
		return "Xplain::ResultSet.load('"+this.setId.replace("#", "%23")+"')";
	},
	this.validate = function(){
		return true;	
	}
}
Load.prototype = Object.create(Operation.prototype)

function Flatten(inputDependencies, position, isVisual){
	Operation.call(this, inputDependencies, isVisual);
	
	this.position = position || "2";
	this.getExpression = function(){
		var prefix = "";
		if(this.isVisual){
			prefix = "v_"
		}
		debugger;
		return this.input[0].getExpression() + "."+prefix+"flatten(level: "+this.position+")"
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
		var pivot = new Pivot(this.input[0]);
		pivot.relations = [new Relation({item: this.relation})];
		pivot.group_by_domain = true;
		debugger
		return pivot.getExpression();
	},
	this.validate = function(){
		return true;
	}
	
}
Project.prototype = Object.create(Operation.prototype)
