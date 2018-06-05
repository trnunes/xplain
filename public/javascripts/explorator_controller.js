/**
 * This code implements all the user interface behaviour of explorator
 * @author samuraraujo
 */
//This method should be executed when the window load.
//Plug the behaviour to the annoted elements.
var XPLAIN = XPLAIN || {}

var uri = '/explorator/'
var createuri = uri + 'create?exp='
var updateuri = uri + 'update?exp='
var executeuri = '/session/execute?exp='
var removeuri = uri + 'remove?exp='
var facetsuri = '/refine/index?'



var currentExecution = null;



//Helper functions defined in explorator_helper.js	
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////SEMANTIC CALCULATOR COMMANDS//////////////////////////
//It used for store the XPLAIN.activeWorkspaceWidget.params_hash

function register_controllers(){
    cmd_set();
	register_landmark_handlers();
}

function register_landmark_handlers(){
	
	$("#all_types").unbind().click(function(){
		XPLAIN.AjaxHelper.get("/session/all_types.json", "json", function(data){
			data.set.intention = "All Types";
			XPLAIN.SetController.appendToWorkspace(data.set);
		});
	});
	
	$("#all_relations").unbind().click(function(){
		XPLAIN.AjaxHelper.get("/session/all_relations.json", "json", function(data){
			data.set.intention = "All Relations";
			XPLAIN.SetController.appendToWorkspace(data.set);
		});
	});
}

/////////////////////////////// SET OPERATIONS //////////////////////////////////////////
function setParameter(item){

    removeCSS($(item).attr('exp'));
    $('.SELECTED').addClass($(item).attr('exp'));
    $(item).addClass($(item).attr('exp'));
    XPLAIN.activeWorkspaceWidget.params_hash.put($(item).attr("id"), $('.SELECTED'));
    removeCSS('SELECTED');
}

//These are the operations applyed over sets
function startOperation(widget){

	if(XPLAIN.activeWorkspaceWidget.params_hash.get("operation")){
		if(operationId == $(widget).attr("operation")){

			return;
		}
		
		var operationId = XPLAIN.activeWorkspaceWidget.params_hash.get("operation");
		var inputParams = XPLAIN.activeWorkspaceWidget.params_hash.get("A");
		var newSelected = $('.SELECTED')
		clear();
		if(newSelected.length){
			newSelected.addClass("SELECTED");
			XPLAIN.activeWorkspaceWidget.params_hash.put("A", newSelected);
		} else {
			inputParams.addClass("SELECTED");
			XPLAIN.activeWorkspaceWidget.params_hash.put("A", inputParams);
		}
		
		XPLAIN.activeWorkspaceWidget.params_hash.put('operation', operationId)
	}

	setParameter(widget);
	$(".active").removeClass("active");
	var operationId = $(widget).attr("operation");
	
	XPLAIN.activeWorkspaceWidget.params_hash.put("operation", operationId);
	$(widget).addClass("active");
	var inputParams = XPLAIN.activeWorkspaceWidget.params_hash.get("A");
	if(inputParams.length == 0){
		alert("Choose at least one item/set to execute the operation!");
		return;
	}
	if(!$(widget).hasClass("set_operation")){
		var setId = $(inputParams[0]).attr("id");
		var operationName = $(widget).attr("operation");
		debugger;
		var operationController = XPLAIN.activeControllers.get(operationName) || eval("new XPLAIN.controllers."+operationName+"Controller(setId);");

		operationController.init();
	}
}
function cmd_set(){
	
    $('#search').unbind().click(function(){
        ajax_keyword_search();
    });    
	
	$("#seachbykeyword").unbind().keyup(function(e){
		
	    if(e.keyCode == 13)
	    {
	        ajax_keyword_search();
			$(this).val("");
	    }
	});
	
	$(".operation").click(function(){
		debugger;
		$(".help").empty();
		startOperation(this);
	});
	
	
	
	$('.param').click(function(){
		if($(this).is(':checkbox')){
			if($(this).is(':checked')){
				XPLAIN.activeWorkspaceWidget.params_hash.put($(this).attr("param"), $(this).attr("param_value"));
			} else {
				XPLAIN.activeWorkspaceWidget.params_hash.remove($(this).attr("param"));
			}
		} else {
			XPLAIN.activeWorkspaceWidget.params_hash.put($(this).attr("param"), $(this).attr("param_value"));
		}
		if($(this).hasClass('filter_comparator')){
			debugger;
			$('.filter_comparator_active').removeClass('filter_comparator_active');
			$(this).addClass('filter_comparator_active');
		}
		
	});
	
    $('._clear').each(function(item){
        $(this).click(function(){
            clear();
        });
    });
	
    $('._equal').unbind().each(function(item){
		debugger;
        $(this).on("click", function(){
			debugger;

			XPLAIN.activeWorkspaceWidget.params_hash.put('B', $('.SELECTED'));

            if(!XPLAIN.currentOperation){
	            if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'union') {
	                XPLAIN.currentOperation = new SemanticExpression('A').union('B').expression;
	            }
	            else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'intersect') 
	                XPLAIN.currentOperation = new SemanticExpression('A').intersection('B').expression;
	            else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'diff') 
	                XPLAIN.currentOperation = new SemanticExpression('A').difference('B').expression;
				else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'pivot') {
					XPLAIN.currentOperation = new SemanticExpression('A').pivot('B').expression;				
				}else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'union') {
	                XPLAIN.currentOperation = new SemanticExpression('A').union('B').expression;
				}else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'join') {
	                XPLAIN.currentOperation = new SemanticExpression('A').join('B').expression;
				}else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'refine') {
					XPLAIN.currentOperation = new SemanticExpression('A').refine().expression;
				} else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'group') {
					XPLAIN.currentOperation = new SemanticExpression('A').group('B').expression;
				} else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'rank') {
					XPLAIN.currentOperation = new SemanticExpression('A').rank('B').expression;
				} else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'map') {
					XPLAIN.currentOperation = new SemanticExpression('A').map('B').expression;
				} else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'merge') {
					XPLAIN.currentOperation = new SemanticExpression('A').merge('B').expression
				} else if (XPLAIN.activeWorkspaceWidget.params_hash.get('operation') == 'flatten') {
					XPLAIN.currentOperation = new SemanticExpression('A').flatten().expression;
				}			
	            else {//spo
	                if (validation_spo()) 
	                    return;
	                XPLAIN.activeWorkspaceWidget.params_hash.put(item.id, Element.exp(item));
	                var view = 'subject_view';
	                if (XPLAIN.activeWorkspaceWidget.params_hash.get(':s') != undefined && XPLAIN.activeWorkspaceWidget.params_hash.get(':p') != undefined && XPLAIN.activeWorkspaceWidget.params_hash.get(':o') == undefined) {
	                    view = 'object_view';
	                }
                
	                XPLAIN.calculate(new SemanticExpression().spo(':s', ':p', ':o', ':r') + "&view=" + view);
                
	            }
            }
			
			if(XPLAIN.currentOperation.execute("json")){
				clear();
			}            
        });
    });
    $('._sum').unbind().each(function(item){
        item.onclick = function(){
            item.up('._WINDOW').sum();
        };
    });
}

//Validates a set (union, intersection or difference) command. A and B must be defined for this operation be success executed.
function validation_set(){
    if (!(XPLAIN.activeWorkspaceWidget.params_hash.get('A') && XPLAIN.activeWorkspaceWidget.params_hash.get('B'))) {
        alert('Parameter A and B must be defined.')
        return true;
    }
    return false;
}

//TODO Move to the refine view controller
function clearFacetModal(){
	$('.filters').empty();
	$("#facetModal .modal-body").hide();
	// $("#facetModal .values_select").empty();
	$('#relation_checkbox').prop('checked', false);
}

function clear(){
	var paramsArray = ['A', 'B', 'S', 'P', 'O', "relation"];
    //Remove all CSS added to which resource selected.
    for (var index in paramsArray){
        removeCSS(paramsArray[index]);
    }
	$("#params_div").hide();
    removeCSS('SELECTED');
	removeCSS('active');
    XPLAIN.activeWorkspaceWidget.params_hash = new Hashtable();
	$('[type=radio]').prop('checked', false);

	$('.filter_comparator_active').removeClass('filter_comparator_active');
	debugger;
	XPLAIN.currentOperation = null;
	clearFacetModal();
	XPLAIN.activeControllers = new Hashtable();
}

function cancel(){
	for(var i in XPLAIN.activeRequests){
		XPLAIN.activeRequests[i].abort();
	}
	// XPLAIN.activeRequests = [];
	$('#loadwindow').hide();
}

function removeCSS(item){
    $('.' + item).removeClass(item);
}
var projection_map = new Hashtable();

function project(set_id, relation) {
	if (projection_map.get(set_id) !== null) {
		if(projection_map.get(set_id).get(relation) !== null) {
			var projection = projection_map.get(set_id).get(relation);
			var tree = $("#" + set_id).find('._items_area').jstree();
			for (var i = 0; i < projection.keys().length; i++) {
				var item_to_be_projected = projection.keys()[i];
				tree.set_text(item_to_be_projected, projection.get(item_to_be_projected));
			}
			return;
		}
	} else {
		if(relation === "ID") {
			var $tree = $("#"+set_id).find("._items_area");
			$($tree.jstree().get_json($tree, {
			  flat: true
			}))
			.each(function(index, value) {
			  var node = $tree.jstree().get_json(this.id);
			  console.log(node);
			  $tree.jstree().set_text(node.id, node.data.item);
			});
		} else {
			ajax_request("/session/project?set=" + set_id + "&relation="+relation);
		}	
	} 	
}

function ajax_keyword_search() {
	
	var inputValues = $("#seachbykeyword").val()
	

	if (inputValues === '') {
		$("#seachbykeyword").fadeOut(50).promise().done(function () {
	        $(this).toggleClass("blink-class").fadeIn(50);
	    });

		alert("Please, type one or more keywords!");
		return this;
	} else {
		$("#seachbykeyword").removeClass("blink-class").fadeIn(50);		
		var valuesArray = inputValues.split(' ');
		if($(".SELECTED").hasClass("set")){
			var refine = new Refine(new Load($(".SELECTED").attr("id")));
			refine.setFilter("keyword_match");
			refine.setFilterParams({keywords: [valuesArray]});
			refine.execute("json");
		} else{
			var keywords_url = "/session/search.json?"
			for (var index in valuesArray){
				keywords_url += "keywords[]=" + valuesArray[index] + "&&"
			}
			XPLAIN.AjaxHelper.get(keywords_url, "json", function(data){
				//TODO the intention should come from the server. Maybe there are two versions of the same intention, one visual and another described by the DSL expression.
				data.set.intention = "Search('"+ valuesArray + "')";
				XPLAIN.SetController.appendToWorkspace(data.set);
			});			
		}
	}
}

function ajax_select() {
	var inputValues = $(".SELECTED").attr("item")
	var keywords_url = "/session/select?"
	if (inputValues === '') {
		return this;
	} else {
		var valuesArray = inputValues.split(' ')
		for (var index in valuesArray){
			keywords_url += "selected[]=" + valuesArray[index] + "&&"
		}
	}
	ajax_request(keywords_url)
	
}


/////////////////////////////// SEMANTIC OPERATIONS //////////////////////////////////////////
///////////////////////////////////// SemanticExpression Class ////////////////////
function SemanticExpression(param) {

	var operationInput = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
	var inputExpression = "";

	var selectExpressionsHash = new Hashtable();
		
	if (operationInput.length > 0) {

		this.expression = new Load(operationInput.attr('data-id'));
		
	} else {
		alert("You must select at least one item/set in the exploration view!");
	}
	debugger;
	console.log("INPUT EXPRESSION: " + this.expression);	
};

SemanticExpression.prototype.flatten = function(){
	this.expression = new Flatten(this.expression);
    return this;
};

SemanticExpression.prototype.union = function(param){
    var setsToUnite = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
    if (setsToUnite == undefined) 
        return this;
    //The parameter could be only one element or several.

    if (!(Object.prototype.toString.call(setsToUnite) === '[object Array]')) {
		setsToUnite = [setsToUnite];
    }
	
    setsToUnite = setsToUnite.map(function(selectedSet){
        return new Load($(selectedSet).attr('data-id'));
    });
	setsToUnite.push(this.expression);
	debugger;
	var union = new Union(setsToUnite);
	this.expression = union;
    return this;
};

SemanticExpression.prototype.intersection = function(param) {
    var setsToIntersect = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
    if (setsToIntersect == undefined) 
        return this;
    //The parameter could be only one element or several.

    if (!(Object.prototype.toString.call(setsToIntersect) === '[object Array]')) {
		setsToIntersect = [setsToIntersect];
    }
	
    setsToIntersect = setsToIntersect.map(function(selectedSet){ return new Load($(selectedSet).attr('data-id')) });	
	setsToIntersect.push(this.expression);
	
	var intersection = new Intersection(setsToIntersect);
	
	this.expression = intersection;
    return this;
};

SemanticExpression.prototype.difference = function(param){
    var setsToDiff = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
    if (setsToDiff == undefined) 
        return this;

    if (!(Object.prototype.toString.call(setsToDiff) === '[object Array]')) {
		setsToDiff = [setsToDiff];
    }

    setsToDiff = setsToDiff.map(function(selectedSet){ return new Load($(selectedSet).attr('data-id')) });	
	setsToDiff.unshift(this.expression);
    //The parameter could be only one element or several.			
    this.expression = new Difference(setsToDiff);

    return this;
};

SemanticExpression.prototype.join = function(param){
    var setsToUnite = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
    if (setsToUnite == undefined) 
        return this;
    //The parameter could be only one element or several.

    if (!(Object.prototype.toString.call(setsToUnite) === '[object Array]')) {
		setsToUnite = [setsToUnite];
    }
	
    setsToUnite = setsToUnite.map(function(selectedSet){
        return new Load($(selectedSet).attr('data-id'));
    });
	setsToUnite.push(this.expression)
	var union = new Join(setsToUnite);
	this.expression = union;
    return this;
};


SemanticExpression.prototype.pivot = function(param){

	var pivot = new Pivot(this.expression, XPLAIN.activeWorkspaceWidget.params_hash.get("level"));
	debugger;
	if(!XPLAIN.activeWorkspaceWidget.params_hash.containsKey('relations')){
		XPLAIN.activeWorkspaceWidget.params_hash.put('relations', []);
		for(var i = 0; i < XPLAIN.activeWorkspaceWidget.params_hash.get('B').length; i++){
			var relation = {item: $(XPLAIN.activeWorkspaceWidget.params_hash.get('B')[i]).attr("item")}
			if($(XPLAIN.activeWorkspaceWidget.params_hash.get('B')[i]).attr("inverse")){
				relation.inverse = eval($(XPLAIN.activeWorkspaceWidget.params_hash.get('B')[i]).attr("inverse"));
			}
			relation.item_type = $(XPLAIN.activeWorkspaceWidget.params_hash.get('B')[i]).attr("item_type")
			
			XPLAIN.activeWorkspaceWidget.params_hash.get('relations').push(relation);
		}
	}
	pivot.setParams(XPLAIN.activeWorkspaceWidget.params_hash);
	this.expression = pivot;
	
	return this;
};

SemanticExpression.prototype.merge = function(param){
	// var targetSet = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
	// if(targetSet === undefined)
	// 	return this;
	// this.expression += ".merge("+$(targetSet).attr('exp')+")";
	return this;
};

SemanticExpression.prototype.refine = function() {
	
	if(XPLAIN.activeWorkspaceWidget.params_hash.get("FacetedRefine")){
		this.expression = XPLAIN.currentOperation;
		if(XPLAIN.activeWorkspaceWidget.params_hash.containsKey('connector')){
			this.expression.setConnector(XPLAIN.activeWorkspaceWidget.params_hash.get('connector'))			
		}
		
		console.log("Refine");
		console.log(this.expression);
		return this;
	}
	var refine = new Refine(this.expression);
	var filter = XPLAIN.activeWorkspaceWidget.params_hash.get("filter");

	var values = "";
	if (filter == 'keyword_match') {

		var inputValues = $("#seachbykeyword").val()

		var valuesArray = inputValues.split(' ');			

		XPLAIN.activeWorkspaceWidget.params_hash.put('values', valuesArray);

		
	} else {
		XPLAIN.activeWorkspaceWidget.params_hash.put("values", $('.SELECTED'));
	}
	refine.setParams(XPLAIN.activeWorkspaceWidget.params_hash);	
	this.expression = refine;
	return this;	
};

SemanticExpression.prototype.group = function(param) {
	
	var group = new Group(this.expression, XPLAIN.activeWorkspaceWidget.params_hash.get("level"));
	
	if (XPLAIN.activeWorkspaceWidget.params_hash.containsKey(param)){
		XPLAIN.activeWorkspaceWidget.params_hash.put('relations', XPLAIN.activeWorkspaceWidget.params_hash.get(param));
	}
	group.setParams(XPLAIN.activeWorkspaceWidget.params_hash);
	this.expression = group;
	return this;	
};

SemanticExpression.prototype.rank = function(param) {
	var rank = new Rank(this.expression);
	if(XPLAIN.activeWorkspaceWidget.params_hash.containsKey(param)){
		XPLAIN.activeWorkspaceWidget.params_hash.put("relations", XPLAIN.activeWorkspaceWidget.params_hash.get(param))
	}
	
	rank.setParams(XPLAIN.activeWorkspaceWidget.params_hash);

	this.expression = rank;
	return this;
};
SemanticExpression.prototype.map = function(param){	
	var mapFunction = XPLAIN.activeWorkspaceWidget.params_hash.get('mapFunction');
	var map = new Map(this.expression, XPLAIN.activeWorkspaceWidget.params_hash.get("level"));
	var mapViewParams = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
	var functionParams = [];
	mapViewParams.each(function(){
		var paramExp = ""
		if($(this).hasClass("set")){
			paramExp = $(this).attr("exp")
		} else if($(this).attr("item_type") == "SchemaRelation"){
			paramExp = "SchemaRelation.new('"+$(this).attr("item")+"')"
		} else if($(this).attr("item_type") == "Item"){
			paramExp = "Item.new('"+$(this).attr("item")+"')"
		} else if($(this).attr("item_type") == "Xpair::Literal"){
			paramExp = "Xpair::Literal.new('"+$(this).attr("item")+"')"
		}
		functionParams.push(paramExp);
		
	});
	
	map.setFunctionParams(functionParams);
	map.setFunction(mapFunction);
	this.expression = map;
	return this;
};

SemanticExpression.prototype.relations = function(){
	this.expression += '.relations()'
	return this;
};

SemanticExpression.prototype.getResourceArray = function(param){
    var a = XPLAIN.activeWorkspaceWidget.params_hash.get(param);
    var expression = '';
    if (a == undefined) 
        return param;
    
    //The parameter could be only one element or several.			
    if (Object.prototype.toString.call(a) === '[object Array]') {
        expression += a.map(function(x){
            var resource = Element.resource(x);
            
            if (resource == 'null' || x.hasClassName('class')) {
                var exp = x.readAttribute('exp');
                if (exp.indexOf(':o,:o') != -1) {
                    return 'SemanticExpression.new' + encodeURIComponent(exp.replace(":o,:o", ':o')) + '.resources(:o)';
                }
                else 
                    if (exp.indexOf(':o,:p') != -1) {
                        return 'SemanticExpression.new' + encodeURIComponent(exp.replace(":o,:p", ':o')) + '.resources(:p)';
                    }
                    else {
                        return 'SemanticExpression.new' + encodeURIComponent(exp) + '.resources(:s)';
                    }
            }
            else {
                return "['" + resource + "']";
            }
        }).join('|');
    }
    return expression; //returns a array of resources in ruby
};

SemanticExpression.prototype.remove = function(s, p, o, r){

    this.expression += '.remove(' + this.getResourcesArray(s) + ',' + this.getResourcesArray(p) + ',' + this.getResourcesArray(o) + ',' + XPLAIN.activeWorkspaceWidget.params_hash.get(r) + ')';
    return this;
};
SemanticExpression.prototype.keyword = function(k){
    this.expression += '.keyword(\'' + k + '\')';
    return this;
};
SemanticExpression.prototype.search = function(k){
    this.expression += '.search(\'' + encodeURIComponent(k) + '\')';
    return this;
};
SemanticExpression.prototype.go = function(k){
    this.expression += '.go(\'' + encodeURIComponent(k) + '\')';
    return this;
};
SemanticExpression.prototype.toString = function(){
    return this.expression;
};
// End of SemanticExpression definition
