/**
 * This code implements all the user interface behaviour of explorator
 * @author samuraraujo
 */
//This method should be executed when the window load.
//Plug the behaviour to the annoted elements.
var uri = '/explorator/'
var createuri = uri + 'create?exp='
var updateuri = uri + 'update?exp='
var executeuri = '/session/execute?exp='
var removeuri = uri + 'remove?exp='
var facetsuri = '/refine/index?'



var currentExecution = null;
var params_hash = new Hashtable();

//Global controller methods
jQuery.fn.extend({
	identify: function(prefix) {
	    var i = 0;
	    return this.each(function() {
	        if(this.id) return;
	        do { 
	            i++;
	            var id = prefix + '_' + i;
	        } while($('#' + id).length > 0);            
	        $(this).attr('id', id);            
	    });
	},
	
	find_relations: function() {
		var setId = $(this).attr("id");
		ajax_request(executeuri + "Xset.load('" + setId + "').find_relations") ;
	},
	
    //remove an element
    ctr_remove: function(item){
        //Removing a resource from a set. Remove an element from a set is the same
        // than do the difference from the original set and the resource
        if ($(this).hasClass('resource')) {
            parameters.put('SET', $(this).parent('._WINDOW'));
            parameters.put('REMOVE', item);
            ajax_update($(this).parents('._WINDOW').first().attr("id"), updateuri + new SemanticExpression('SET').difference('REMOVE') + '&uri=' + $(this).parents('._WINDOW').first().attr("id"));
        }
        else {
            //Removing a entire set
            ajax_remove('/explorator/execute?exp=remove(\'' + $(this).attr("id") + '\')');
        }
    },
	
    crt_refresh: function(item, view, filter){
        //reload the set .         		   	  
        ajax_update($(this).attr("id"), executeuri + 'refresh(\'' + $(this).attr("id") + '\',:' + view + ',\'' + filter + '\')');
    },
	
    //open a new window where his content will be defined by the item.exp attribute.
    ctr_open: function(item){
        _uri = '/repository/autoadd?uri=' + $(this).resource();
		$.ajax({
			type: "GET",
			url: _uri,
			data_type: "script"
		});
        parameters.put('O', $(this));
        XPAIR.calculate(new SemanticExpression('O') + '&view=' + $(this).attr('view'));
    },
	
	//TODO: corrigir a geração de facetas.
    //Create or replace the facet window with a new content.
    crt_refine: function(item, name){
        facetoriginalexpression = null;

        if ($('#facets').size() > 0) {
            ajax_update('facets', facetsuri  + '&name=' + name);
        }
        else {
        
            ajax_request_forfacet(facetsuri + '&name=' + name, $(this));
        }
    },//Create or replace the facet window with a new content.
	
	//TODO: corrigir a geração de facetas.
    crt_infer: function(item){
        facetoriginalexpression = null;
        
        facetsetmove(item);
        if ($('#facets').size() > 0) {
            ajax_update('facets', facetsuri + 'infer' + $(this).exp());
        }
        else {
        
            ajax_request_forfacet(facetsuri + 'infer' + $(this).exp(), item);
        }
    },
    
	//TODO: corrigir a geração de facetas.
    crt_dofacet: function(item){
        facetwindow = $(item).parent('._WINDOW').parent('._WINDOW');
        if (facetoriginalexpression == null) {
            facetoriginalexpression = $(facetwindow).attr('exp');
        }
        $(facetwindow).attr('exp', facetoriginalexpression);
        parameters.put('C', facetwindow);
        expression = new SemanticExpression('C');
        $(".values").each(function(x){
            allchecked = $("._checkboxfacet:checked");
            if (allchecked.size() > 0) {
                parameters.put('A', allchecked);
                expression.intersection('A');
            }
        });
        ajax_update($(facetwindow).attr('set'), updateuri + expression + '&uri=' + set(facetwindow));
        $(item).parent('.facetgroupwindow').children('.tranparentpanel').css({
            display: 'block',
            position: 'absolute',
            width: '100%',
            height: '100%'
        });
        
    },
    sum: function(){
        ajax_update($(this).attr("id"), uri + "sum?uri=" + $(this).attr("id"));
    },
    set: function(item){
        return encodeURIComponent($(item).attr('set'));
    },
    resource: function(){
        return encodeURIComponent($(this).attr('resource'));
    },
    exp: function(){
        return encodeURIComponent($(this).attr('exp'));
    }
});

//Helper functions defined in explorator_helper.js	
///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////SEMANTIC CALCULATOR COMMANDS//////////////////////////
//It used for store the parameters
var parameters = new Hashtable();
function register_controllers(){
    cmd_set();
    cmd_semantic();
	register_landmark_handlers();
}

function register_landmark_handlers(){
	$("#all_types").unbind().click(function(){
		XPAIR.AjaxHelper.get("/session/all_types.json", "json", function(data){
			var xset = new XPAIR.Xset(data.set);
			xset.setIntention("All Types")
			var xsetAdapter = new XPAIR.adapters.JstreeAdapter(xset);
			new XPAIR.projections.Jstree(xsetAdapter).init();
		});
	});
	
	$("#all_relations").unbind().click(function(){
		XPAIR.AjaxHelper.get("/session/all_relations.json", "json", function(data){
			var xset = new XPAIR.Xset(data.set);
			xset.setIntention("All Relations");
			
			var xsetAdapter = new XPAIR.adapters.JstreeAdapter(xset);
			
			new XPAIR.projections.Jstree(xsetAdapter).init();
		});
	});
}

/////////////////////////////// SET OPERATIONS //////////////////////////////////////////
function setParameter(item){

    removeCSS($(item).exp());
    $('.SELECTED').addClass($(item).exp());
    $(item).addClass($(item).exp());
    parameters.put($(item).attr("id"), $('.SELECTED'));
    removeCSS('SELECTED');
}
function setupRefineControls(){
	$("#facetedRefine").click(function(){

		XPAIR.currentSession.getProjections($("._WINDOW.A").attr("id"))[0].activateFacetedFiltering();

	});
	$("[name=filterradio]").click(function(){
		XPAIR.addParameter("relation", $(".SELECTED"));
	})
}
//These are the operations applyed over sets
function startOperation(widget){
	if(parameters.get("operation")){
		if(operationId == $(widget).attr("operation")){
			return;
		}
		
		var operationId = parameters.get("operation");
		var inputParams = parameters.get("A");
		var newSelected = $('.SELECTED')
		clear();
		if(newSelected.length){
			newSelected.addClass("SELECTED");
			parameters.put("A", newSelected);
		} else {
			inputParams.addClass("SELECTED");
			parameters.put("A", inputParams);
		}
		
		parameters.put('operation', operationId)
	}

	setParameter(widget);
	$(".active").removeClass("active");
	var operationId = $(widget).attr("operation");
	
	parameters.put("operation", operationId);
	$(widget).addClass("active");
	var inputParams = parameters.get("A");
	if(inputParams.length == 0){
		alert("Choose at least one item/set to execute the operation!");
		return;
	}
	if(!$(widget).hasClass("set_operation")){
		var setId = $(inputParams[0]).attr("id");
		var operationName = $(widget).attr("operation");
		debugger;
		var operationController = XPAIR.activeControllers.get(operationName) || eval("new XPAIR.controllers."+operationName+"Controller(XPAIR.currentSession.getSet(setId));");

		operationController.init();
	}
}
function cmd_set(){
	
	$(".operation").click(function(){
		startOperation(this);
	});
	
	
	$('.param').click(function(){
		if($(this).is(':checkbox')){
			if($(this).is(':checked')){
				parameters.put($(this).attr("param"), $(this).attr("param_value"));
			} else {
				parameters.remove($(this).attr("param"));
			}
		} else {
			parameters.put($(this).attr("param"), $(this).attr("param_value"));
		}
		if($(this).hasClass('filter_comparator')){
			debugger;
			$('.filter_comparator_active').removeClass('filter_comparator_active');
			$(this).addClass('filter_comparator_active');
		}
		
	});	
	// setupRefineControls();
	//
	// $("#rank_criteria").unbind().click(function(e){
	// 	var inputParams = parameters.get("A");
	// 	if(inputParams.length == 0){
	// 		alert("Choose a set to rank!");
	// 		return;
	// 	}
	//
	// 	var setId = $(inputParams[0]).attr("id");
	//
	// 	var rankController = new XPAIR.controllers.RankController(XPAIR.currentSession.getSet(setId));
	//
	// 	rankController.init();
	// });
	//
	// $("#faceted_filter").unbind().click(function(e){
	// 	var inputParams = parameters.get("A");
	// 	if(inputParams.length == 0){
	// 		alert("Choose a set to refine!");
	// 		return;
	// 	}
	//
	// 	var setId = $(inputParams[0]).attr("id");
	//
	// 	var refineController = new XPAIR.controllers.RefineController(XPAIR.currentSession.getSet(setId));
	//
	// 	refineController.init();
	// });
	//
	// $("[operation='Pivot']").unbind().click(function(e){
	// 	var inputParams = parameters.get("A");
	// 	if(inputParams.length == 0){
	// 		alert("Choose a set to pivot!");
	// 		return;
	// 	}
	//
	// 	var setId = $(inputParams[0]).attr("id");
	//
	// 	var pivotController = new XPAIR.controllers.PivotController(XPAIR.currentSession.getSet(setId));
	// 	debugger;
	//
	// 	pivotController.init();
	// });
	
	
	
    $('._equal').unbind().each(function(item){
		debugger;
        $(this).on("click", function(){
			debugger;

			parameters.put('B', $('.SELECTED'));

            if(!XPAIR.currentOperation){
	            if (parameters.get('operation') == 'union') {
	                XPAIR.currentOperation = new SemanticExpression('A').union('B').expression;
	            }
	            else if (parameters.get('operation') == 'intersect') 
	                XPAIR.currentOperation = new SemanticExpression('A').intersection('B').expression;
	            else if (parameters.get('operation') == 'diff') 
	                XPAIR.currentOperation = new SemanticExpression('A').difference('B').expression;
				else if (parameters.get('operation') == 'pivot') {
					XPAIR.currentOperation = new SemanticExpression('A').pivot('B').expression;				
				}else if (parameters.get('operation') == 'union') {
	                XPAIR.currentOperation = new SemanticExpression('A').union('B').expression;
				}else if (parameters.get('operation') == 'join') {
	                XPAIR.currentOperation = new SemanticExpression('A').join('B').expression;
				}else if (parameters.get('operation') == 'refine') {
					XPAIR.currentOperation = new SemanticExpression('A').refine().expression;
				} else if (parameters.get('operation') == 'group') {
					XPAIR.currentOperation = new SemanticExpression('A').group('B').expression;
				} else if (parameters.get('operation') == 'rank') {
					XPAIR.currentOperation = new SemanticExpression('A').rank('B').expression;
				} else if (parameters.get('operation') == 'map') {
					XPAIR.currentOperation = new SemanticExpression('A').map('B').expression;
				} else if (parameters.get('operation') == 'merge') {
					XPAIR.currentOperation = new SemanticExpression('A').merge('B').expression
				} else if (parameters.get('operation') == 'flatten') {
					XPAIR.currentOperation = new SemanticExpression('A').flatten().expression;
				}			
	            else {//spo
	                if (validation_spo()) 
	                    return;
	                parameters.put(item.id, Element.exp(item));
	                var view = 'subject_view';
	                if (parameters.get(':s') != undefined && parameters.get(':p') != undefined && parameters.get(':o') == undefined) {
	                    view = 'object_view';
	                }
                
	                XPAIR.calculate(new SemanticExpression().spo(':s', ':p', ':o', ':r') + "&view=" + view);
                
	            }
            }
			
			if(XPAIR.currentOperation.execute("json")){
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
    if (!(parameters.get('A') && parameters.get('B'))) {
        alert('Parameter A and B must be defined.')
        return true;
    }
    return false;
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
    parameters = new Hashtable();
	for(var i in XPAIR.currentSession.allProjections()){

		XPAIR.currentSession.allProjections()[i].clear();
	}
	$('[type=radio]').prop('checked', false);
	var projections = XPAIR.currentSession.allProjections();
	for(var i in projections){
		projections[i].getAdapter().clear();
	}
	
	$('.filter_comparator_active').removeClass('filter_comparator_active');
	XPAIR.currentOperation = null;
	clearFacetModal();
	XPAIR.activeControllers = new Hashtable();
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
			XPAIR.AjaxHelper.get(keywords_url, "json", function(data){
				var xset = new XPAIR.Xset(data.set);
				xset.setIntention("Search('"+ valuesArray + "')");

				var xsetAdapter = new XPAIR.adapters.JstreeAdapter(xset);
				var proj = new XPAIR.projections.Jstree(xsetAdapter);
				proj.init();

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
//These are the operations applyed over triples or semantics annotations
function cmd_semantic(){
    $('._clear').each(function(item){
        $(this).click(function(){
            clear();
        });
    });
    //Add a listener for the keyword search. 
    //This observer is applied over the form id_form_keyword
    $('load').onclick = function(){
        new Ajax.Request('/repository/enable?title=EXPLORATOR(Local)', {
            method: 'get'
        });
        
        XPAIR.calculate(new SemanticExpression().go($F('seachbykeyword')));
        ajax_update('listenabledrepositories', '/repository/listenabledrepositories');
    };
	
    $('#search').unbind().click(function(){
        ajax_keyword_search();
    });    
	$("#seachbykeyword").unbind().keyup(function(e){
		debugger;
	    if(e.keyCode == 13)
	    {
	        ajax_keyword_search();
			$(this).val("");
	    }
	});
    
    // $('id_form_keyword').onsubmit = function(){
    //     if ($F('seachbykeyword').indexOf('http://') != -1)
    //         XPAIR.calculate(new SemanticExpression().go($F('seachbykeyword')));
    //     else
    //
    //         XPAIR.calculate(new SemanticExpression().search($F('seachbykeyword')));
    //     return false;
    // };
    
    
    //Add a listener for the facet create form. 
    //This observer is applied over the form id_form_facet
    $('._form_facet').each(function(item){
        item.onsubmit = function(){
            parameters.put('A', $('.SELECTED'));
            ajax_request("/facets/create?name=" + $F(this['facetname']) + "&exp=" + new SemanticExpression('A'));
            clear();
            return false;
        };
    });
    
    $('._facetlist').each(function(item){
        item.onchange = function(){
            //gets the set that has been faceted and computes the facet again.	 
            $('div#facetgroup > div:nth-child(3)')[0].crt_facet($F(this));
            return false;
        };
    });
}

///////////////////////////////////// SemanticExpression Class ////////////////////
function SemanticExpression(param) {

	var operationInput = parameters.get(param);
	var inputExpression = "";

	var selectExpressionsHash = new Hashtable();
	if(parameters.get("level") > 1){

		this.expression = new Expression(operationInput.first().parents("._WINDOW").attr("exp"));
	} else {
		
		if (operationInput.length > 0) {
			this.expression = XPAIR.generateExpressionFromSelection(operationInput);
			
		} else {
			alert("You must select at least one item/set in the exploration view!");
		}
		
		
	}
		
	
	console.log("INPUT EXPRESSION: " + this.expression);	
};

SemanticExpression.prototype.flatten = function(){
	this.expression = new Flatten(this.expression);
    return this;
};

SemanticExpression.prototype.union = function(param){
    var setsToUnite = parameters.get(param);
    if (setsToUnite == undefined) 
        return this;
    //The parameter could be only one element or several.

    if (!(Object.prototype.toString.call(setsToUnite) === '[object Array]')) {
		setsToUnite = [setsToUnite];
    }
	
    setsToUnite = setsToUnite.map(function(selectedSet){
        return new Load($(selectedSet).attr('id'));
    });
	setsToUnite.push(this.expression)
	var union = new Union(setsToUnite);
	this.expression = union;
    return this;
};

SemanticExpression.prototype.intersection = function(param) {
    var setsToIntersect = parameters.get(param);
    if (setsToIntersect == undefined) 
        return this;
    //The parameter could be only one element or several.

    if (!(Object.prototype.toString.call(setsToIntersect) === '[object Array]')) {
		setsToIntersect = [setsToIntersect];
    }
	
    setsToIntersect = setsToIntersect.map(function(selectedSet){ return new Load($(selectedSet).attr('id')) });	
	setsToIntersect.push(this.expression);
	
	var intersection = new Intersection(setsToIntersect);
	
	this.expression = intersection;
    return this;
};

SemanticExpression.prototype.difference = function(param){
    var setsToDiff = parameters.get(param);
    if (setsToDiff == undefined) 
        return this;

    if (!(Object.prototype.toString.call(setsToDiff) === '[object Array]')) {
		setsToDiff = [setsToDiff];
    }

    setsToDiff = setsToDiff.map(function(selectedSet){ return new Load($(selectedSet).attr('id')) });	
	setsToDiff.unshift(this.expression);
    //The parameter could be only one element or several.			
    this.expression = new Difference(setsToDiff);

    return this;
};

SemanticExpression.prototype.join = function(param){
    var setsToUnite = parameters.get(param);
    if (setsToUnite == undefined) 
        return this;
    //The parameter could be only one element or several.

    if (!(Object.prototype.toString.call(setsToUnite) === '[object Array]')) {
		setsToUnite = [setsToUnite];
    }
	
    setsToUnite = setsToUnite.map(function(selectedSet){
        return new Load($(selectedSet).attr('id'));
    });
	setsToUnite.push(this.expression)
	var union = new Join(setsToUnite);
	this.expression = union;
    return this;
};


SemanticExpression.prototype.pivot = function(param){

	var pivot = new Pivot(this.expression, parameters.get("level"));
	debugger;
	if(!parameters.containsKey('relations')){
		parameters.put('relations', []);
		for(var i = 0; i < parameters.get('B').length; i++){
			var relation = {item: $(parameters.get('B')[i]).attr("item")}
			if($(parameters.get('B')[i]).attr("inverse")){
				relation.inverse = eval($(parameters.get('B')[i]).attr("inverse"));
			}
			relation.item_type = $(parameters.get('B')[i]).attr("item_type")
			
			parameters.get('relations').push(relation);
		}
	}
	pivot.setParams(parameters);
	this.expression = pivot;
	
	return this;
};

SemanticExpression.prototype.merge = function(param){
	// var targetSet = parameters.get(param);
	// if(targetSet === undefined)
	// 	return this;
	// this.expression += ".merge("+$(targetSet).attr('exp')+")";
	return this;
};

SemanticExpression.prototype.refine = function() {
	
	if(parameters.get("FacetedRefine")){
		this.expression = XPAIR.currentOperation;
		if(parameters.containsKey('connector')){
			this.expression.setConnector(parameters.get('connector'))			
		}
		
		console.log("Refine");
		console.log(this.expression);
		return this;
	}
	var refine = new Refine(this.expression);
	var filter = parameters.get("filter");

	var values = "";
	if (filter == 'keyword_match') {

		var inputValues = $("#seachbykeyword").val()

		var valuesArray = inputValues.split(' ');			

		parameters.put('values', valuesArray);

		
	} else {
		parameters.put("values", $('.SELECTED'));
	}
	refine.setParams(parameters);	
	this.expression = refine;
	return this;	
};

SemanticExpression.prototype.group = function(param) {
	
	var group = new Group(this.expression, parameters.get("level"));
	
	if (parameters.containsKey(param)){
		parameters.put('relations', parameters.get(param));
	}
	group.setParams(parameters);
	this.expression = group;
	return this;	
};

SemanticExpression.prototype.rank = function(param) {
	var rank = new Rank(this.expression);
	if(parameters.containsKey(param)){
		parameters.put("relations", parameters.get(param))
	}
	
	rank.setParams(parameters);

	this.expression = rank;
	return this;
};
SemanticExpression.prototype.map = function(param){	
	var mapFunction = parameters.get('mapFunction');
	var map = new Map(this.expression, parameters.get("level"));
	var mapViewParams = parameters.get(param);
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
    var a = parameters.get(param);
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
SemanticExpression.prototype.spo = function(s, p, o, r){
    
    this.expression += '.spo(' + this.getResourcesArray(s) + ',' + this.getResourcesArray(p) + ',' + this.getResourcesArray(o) + ',' + parameters.get(r) + ')';
    return this;
};
SemanticExpression.prototype.remove = function(s, p, o, r){

    this.expression += '.remove(' + this.getResourcesArray(s) + ',' + this.getResourcesArray(p) + ',' + this.getResourcesArray(o) + ',' + parameters.get(r) + ')';
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
function preDefinedFilter(el){
    Element.extend(el);
    var win = el.up('._WINDOW');
    var exp = Element.exp(win);
    
    var select = el.previous('select');
    
    var operator = $F(select);
    var value = el.value;
    
    ajax_update(win.id, uri + "addfilter?uri=" + win.id + "&op=" + operator + "&value=" + value);
}

