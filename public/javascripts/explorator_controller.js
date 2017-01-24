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

var XPAIR = XPAIR || {};
XPAIR.currentsession = new Session("current");

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
        ajax_create(new SemanticExpression('O') + '&view=' + $(this).attr('view'));
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
}

/////////////////////////////// SET OPERATIONS //////////////////////////////////////////
function setParameter(item){
    removeCSS($(item).exp());
    $('.SELECTED').addClass($(item).exp());
    $(item).addClass($(item).exp());
    parameters.put($(item).attr("id"), $('.SELECTED'));
    removeCSS('SELECTED');
}

//These are the operations applyed over sets
function cmd_set(){
    $('._setparameter').unbind().each(function(item){
        $(this).on("click", function(){
            setParameter(item);
        });
    });
	
	
	$('._relations').unbind().each(function(){
		$(this).click(function(){
	        if ($('.SELECTED').size() != 1) {
	            alert("Select JUST 1 set to find the relations.");
	        }
	        else {
	            if ($('.SELECTED').first().hasClass('resource')) {
	                alert('You can only facet a SET not a RESOURCE.')
	                return;
	            }
				parameters.put('A', $('.SELECTED').first())                
	            ajax_create(new SemanticExpression('A').relations());
	        }
		});
	});	
	
	$('._query').unbind().each(function(item){
		$(this).on("click", function(){
			parameters.put('operation', 'query');			
		});
	});
    $('._union').unbind().click(function(){
            setParameter(this);
            parameters.put('operation', 'union');        
    });
    
    $('._intersection').unbind().each(function(item){
        $(this).on("click", function(){
            setParameter(this);
            parameters.put('operation', 'intersection');
        });
    });
    $('._difference').unbind().each(function(item){
        $(this).on("click", function(){
            setParameter(this);
            parameters.put('operation', 'difference');
        });
    });
	$('._refine').unbind().click(function(event){
		setParameter(this)
		parameters.put('operation', 'refine');
		render_refine_toolbar();
		
	});
	
	$('._facets').unbind().click(function(event){
		setParameter(this);
		$.ajax(	{			
			type: "GET",
			url: "/session/relations?id="+node_to_open.text,
			data_type: "script",
			success: function(data, status, jqrequest) {

				console.log(relations_subtree);
				for (var i = 0; i < relations_json.length; i++) {
					$('#<%=@resourceset.id%>').find('._items_area').jstree().create_node(node_to_open, relations_json[i], "first");
				}

			}
		});
		
	});
	$('._group').unbind().click(function(event){
		setParameter(this)
		parameters.put('operation', 'group')
		render_group_toolbar();
	});
	$('._rank').unbind().click(function(event){
		setParameter(this)
		parameters.put('operation', 'rank');
		render_rank_toolbar();
	});
	$('._merge').unbind().click(function(event){
		setParameter(this)
		parameters.put('operation', 'merge');
	});
	
	$('._pivot').unbind().click(function(event){
		setParameter(this)
		parameters.put('operation', 'pivot')
	});
	
	$('._map').unbind().click(function(event){
		setParameter(this);
		parameters.put('operation', 'map');
		render_map_toolbar();
	});
    $('._delete').unbind().each(function(item){
        $(this).on("click", function(){
            if (validation_spo()) 
                return;
            parameters.put($(this).attr("id"), $(this).exp());
            var view = 'subject_view';
            if (parameters.get(':s') != undefined && parameters.get(':p') != undefined && parameters.get(':o') == undefined) {
                view = 'object_view';
            }
            ajax_create(new SemanticExpression().remove(':s', ':p', ':o', ':r') + "&view=" + view);
            clear();
        });
    });
	
	
    $('._equal').unbind().each(function(item){
        $(this).on("click", function(){
            parameters.put('B', $('.SELECTED'));
            if (parameters.get('operation') == 'union') {
                ajax_create(new SemanticExpression('A').union('B'));
            }
            else if (parameters.get('operation') == 'intersection') 
                ajax_create(new SemanticExpression('A').intersection('B'));
            else if (parameters.get('operation') == 'difference') 
                ajax_create(new SemanticExpression('A').difference('B'));
			else if (parameters.get('operation') == 'pivot') {
				ajax_create(new SemanticExpression('A').pivot('B'));
			} else if (parameters.get('operation') == 'refine') {
				ajax_create(new SemanticExpression('A').refine());
			} else if (parameters.get('operation') == 'group') {
				ajax_create(new SemanticExpression('A').group('B'));
			} else if (parameters.get('operation') == 'rank') {
				ajax_create(new SemanticExpression('A').rank());
			} else if (parameters.get('operation') == 'map') {
				ajax_create(new SemanticExpression('A').map());
			} else if (parameters.get('operation') == 'merge') {
				ajax_create(new SemanticExpression('A').merge('B'))
			}
            else {//spo
                if (validation_spo()) 
                    return;
                parameters.put(item.id, Element.exp(item));
                var view = 'subject_view';
                if (parameters.get(':s') != undefined && parameters.get(':p') != undefined && parameters.get(':o') == undefined) {
                    view = 'object_view';
                }
                
                ajax_create(new SemanticExpression().spo(':s', ':p', ':o', ':r') + "&view=" + view);
                
            }
            clear();
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

//Validates a spo command. S, P or O must be defined for this operation be success executed.
function validation_spo(){
    if ((!parameters.get(':s') && !parameters.get(':p') && !parameters.get(':o'))) {
        alert('Parameter S, P or O must be defined.')
        return true;
    }
    return false;
}

function clear(){
	var paramsArray = ['A', 'B', 'S', 'P', 'O'];
    //Remove all CSS added to which resource selected.
    for (var index in paramsArray){
        removeCSS(paramsArray[index]);
    }
	$("#params_div").hide();
    removeCSS('SELECTED');
    parameters = new Hashtable();
    
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
		}
	}
	
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
	}
	$.ajax({
		type: "GET",
		url: "/session/project?set=" + set_id + "&relation="+relation,
		data_type: "script",
		success: function(data, status, jqrequest) {
			
		}
	});
}

function ajax_keyword_search() {
	var inputValues = $("#seachbykeyword").val()
	var keywords_url = "/session/search?"
	if (inputValues === '') {
		return this;
	} else {
		var valuesArray = inputValues.split(' ')
		for (var index in valuesArray){
			keywords_url += "keywords[]=" + valuesArray[index] + "&&"
		}
	}
	ajax_request(keywords_url)
}

function ajax_select() {
	var inputValues = $(".SELECTED").attr("resource")
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
        
        ajax_create(new SemanticExpression().go($F('seachbykeyword')));
        ajax_update('listenabledrepositories', '/repository/listenabledrepositories');
    };
	
    $('#search').unbind().click(function(){
        ajax_keyword_search();
    });    
    
    $('id_form_keyword').onsubmit = function(){
        if ($F('seachbykeyword').indexOf('http://') != -1) 
            ajax_create(new SemanticExpression().go($F('seachbykeyword')));
        else 
        
            ajax_create(new SemanticExpression().search($F('seachbykeyword')));
        return false;
    };
    
    
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

function pivot(set_view, isForward, isPath) {
	var setExpr = "Xset.load('" + set_view.attr("id").replace("#", "%23") + "')";
	var pivotExpr = "";
	if (isForward) {
		pivotExpr = ".pivot_forward(";
	}else {
		pivotExpr = ".pivot_backward(";
	}


	if (isPath) {
		pivotExpr += get_path_expr();
	} else {
		pivotExpr += get_multiple_relations_expr();
	}
	pivotExpr += ")";
	console.log("PIVOT EXPR: " + setExpr+pivotExpr)
	ajax_create(setExpr+pivotExpr);
}

function get_path_expr() {
	var path_expr = "[[";
	$(".SELECTED").each(function(){
		path_expr += "'" + $(this).attr("resource") + "',"
		
	});
	path_expr += "]]";
	console.log("PATH EXPRESSION: " + path_expr);
	return path_expr;
}

function get_multiple_relations_expr() {
	var multiple_relations_expr = "[";
	$(".SELECTED").each(function(){
		multiple_relations_expr += "'" + $(this).attr("resource") + "',"
		
	});
	multiple_relations_expr += "]";
	console.log("MULTIPLE RELATIONS EXPRESSION: " + multiple_relations_expr);
	return multiple_relations_expr;	
}

///////////////////////////////////// SemanticExpression Class ////////////////////
function SemanticExpression(param) {
	var inputSet = parameters.get(param)
    if (param != undefined) {
        this.expression = "Xset.load('" + $(inputSet).attr("id").replace("#", "%23") + "')";
    }	
};

SemanticExpression.prototype.union = function(param){
    var a = parameters.get(param);
    if (a == undefined) 
        return this;
    //The parameter could be only one element or several.
    if (Object.prototype.toString.call(a) === '[object Array]') {
        this.expression += a.map(function(x){
            return '.union(' + $(x).attr('exp') + ')';
        }).join('');
    }
    else {
		
        this.expression += '.union(' + a.attr('exp') + ')';
		alert(this.expression);
    }
    return this;
}
SemanticExpression.prototype.intersection = function(param) {
    var a = parameters.get(param);
    if (a == undefined) 
        return this;
    //The parameter could be only one element or several.
    if (Object.prototype.toString.call(a) === '[object Array]') {
		
        this.expression += a.map(function(inputElem){
			return '.intersect(' + $(inputElem).attr("exp") + ')'
		}).join('');        
    }
    else {
        this.expression += '.intersect(' + $(a).attr("exp") + ")";
    }
    return this;
};
SemanticExpression.prototype.difference = function(param){
    var a = parameters.get(param);
    if (a == undefined) 
        return this;
    //The parameter could be only one element or several.			
    if (Object.prototype.toString.call(a) === '[object Array]') {
        this.expression += a.map(function(x){
            return '.diff(' + $(x).attr("exp") + ")";
        }).join('');
    }
    else {
        this.expression += '.diff(' + $(a).attr("exp") + ")";
    }
    return this;
};

SemanticExpression.prototype.pivot = function(param){
	var targetRelation = parameters.get(param);
	
	if(targetRelation === undefined)
		return this;
	
	this.expression += ".pivot_forward(['" +$(targetRelation).attr('resource').replace("#", "%23")+ "'])"
	return this;
	
};

SemanticExpression.prototype.merge = function(param){
	var targetSet = parameters.get(param);
	if(targetSet === undefined)
		return this;
	this.expression += ".merge("+$(targetSet).attr('exp')+")";
	return this;
};

SemanticExpression.prototype.refine = function() {

	var filter = parameters.get("filter")
	var values = "";
	if (filter == 'keyword_match') {
		var inputValues = $("#keywords_input").val()
		if (inputValues === '') {
			return this;
		} else {
			var valuesArray = inputValues.split(' ')
			for (var index in valuesArray){
				values += "'" + valuesArray[index] + "',"				
			}
			values = "[["+values+"]]"			
		}
		this.expression += ".refine{|f| f."+ filter+"(" +values+")}"
		
	} else {

		var valuesArray = $('.SELECTED')
		console.log(valuesArray.toString());
		if(valuesArray.size() > 1) {
			for (var index =0; index < valuesArray.length; index++){
				values += "'" + $(valuesArray[index]).attr("resource").replace("#", "%23") + "'"	
				if(index < valuesArray.length - 1) {
					values += ",";
				}
			}
			values = "["+values+"]"			
		} else {
			console.log(valuesArray);
			values = "'"+$(valuesArray).attr("resource").replace("#", "%23")+"'"
		}
		var relation = parameters.get("relation").attr('resource').replace("#", "%23")
		this.expression += ".refine{|f| f."+ filter+"('"+relation+"', " + values + ")}"
	}	
	return this;
	
};

SemanticExpression.prototype.group = function() {
	var relation = parameters.get("relation").attr('resource').replace("#", "%23");
	if (relation === '') {
		return this;
	}
	
	this.expression += ".group('"+relation+"')"
	return this;	
};

SemanticExpression.prototype.rank = function() {
	var ranking_function = parameters.get("ranking_function");
	this.expression += ".rank"
	if(ranking_function == 'image_count') {
		var target_set = parameters.get('target_set');
		this.expression += "{|ranking_function| ranking_function.each_image_count("+$(target_set).attr("exp")+")}"
		
	}	
	return this;
};
SemanticExpression.prototype.map = function(){	
	var map_function = parameters.get('map_function');
	var inputSetExp = this.expression;
	this.expression += ".map{|map_function|"
	if (map_function === 'domain_count'){
		var target_set = parameters.get('target_set')
		this.expression += "map_function.domain_count("+  $(target_set).attr("exp") + ".merge(" +inputSetExp +"))"
	} else {
		this.expression += "map_function." + map_function
	}
	this.expression += "}"
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

