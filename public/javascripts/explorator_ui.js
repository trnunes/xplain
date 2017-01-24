/**
 * This code implements all the user interface behaviour of explorator
 * @author samuraraujo
 */
//Add global ui methods to the elements
jQuery.fn.extend({
    //Hide an element
    ui_hide: function(item){
		// $(this).hide("blind", {direction: "up"}, 1000);
    },
    //Show an element
    ui_show: function(item){
    	$(this).show("blind", {direction: "down"}, 1000);        
    }, //maximize a window
	
    //remove an element
    ui_remove: function(item){
        //removes the element from the model and replace the interface with a new one.
        $(this).remove();
    }, //close an element
    ui_close: function(item){

    	$(this).find("._items_area").jstree().destroy();
		$(this).remove();
		
    }, //open an element
    ui_open: function(item){
    
        $(this).ctr_open();
    }
});

//This method should be executed when the window load.
//Plug the behaviour to the annoted elements.
function register_ui_behaviour(){
    //Initialize window behaviour.
    register_ui_window_behaviour();
    //Initialize de selection behaviour.
    register_ui_selection_behaviour();
    //Initialize de resource behaviour.
    register_ui_resource_behaviour();
}

function create_pivot_menu(set_id) {
	console.log("#" + set_id + " .pivot_button");
    $(function() {
		var isForward = true;
		var isPath = false;
		var isMultiple = false;		
		$.contextMenu({
		  selector: "#" + set_id + " .pivot_button",
		  trigger: 'left',
		  callback: function(key, options) {
		      var m = "clicked: " + key;
		      window.console && console.log(m) || alert(m); 
		  },
		  items: {
		      "forward": {name: "Forward", selected: true, type: "radio"},
		      "backward": {name: "Backward", type: "radio", events: {change: function(e){isForward = false}}},                 
		      "sep1": "---------",
			  "path": {name: "Path", type: "checkbox", events: {change: function(e){isPath = true}}},
			  "multiple": {name: "Multiple", type: "checkbox", events: {change: function(e){isMultiple = true}}},
			  "sep2": "---------",
			  key: {
				  name: "Pivot", 
				  callback: function(){				  
					  pivot($("#" + set_id), isForward, isPath);
					  isForward = true;
					  isPath = false;
					  isMultiple = false;
				  }
		      },
		      "quit": {name: "Quit", icon: function(){
		          return 'context-menu-icon context-menu-icon-quit';
		      }}
		  },

		});

		$("#" + set_id + " .pivot_button").on('click', function(e){
		  console.log('clicked', this);
		})    
		});
}

function create_set_context_menu(set_id){
	console.log("#" + set_id + " .project_button");
	$.ajax(	{
		type: "GET",
		url: '/session/common_relations?set='+set_id,
		data_type: "script",
		success: function(data, status, jqrequest) {
			$.contextMenu({
			    selector: "#" + set_id + " .project_button",
				trigger: 'left',
			    build: function($triggerElement, e){
			        return {
						items:{
						    select: {
						        name: "Select a relation", type: 'select', options: common_relations_menu,
						        events: {
						            change: function (e) {
										var selectedRelation = $(e.target).find(":selected").text();
										project(set_id, selectedRelation);
						            }
						        }
							}
						}
					};
				}
			});
		}
	});
}
////////////////////////////////////////////////////////////////////////////////////////////////////////	
//////////////////////////////RESOURCE BEHAVIOURS/////////////////////////////////////////////////////////
function register_ui_resource_behaviour(){
    //Add window show behaviour to the elements with  _MINIMIZE annotation 
    $('.resource').each(function(resource){
        $(this).identify();
        $(this).dblclick(function(e){
            $(this).ui_open();
            $('#loadingtext').innerHTML = "Loading: " + getTextValue(resource);
            e.stopPropagation();
        });
        //	   resource.onclick = function(e){        
        //		   $('seachbykeyword').value=resource.readAttribute('resource');
        //  			e.stopPropagation();
        //        };
        
       
    });
	
    
    
    $('.all').each(function(resource){
        $(this).identify();
        $(this).click(function(e){
            $(this).ui_open();
            e.stopPropagation();
        });        
    });
	
    $('.instances').each(function(item){
        $(this).identify();
        $(this).click(function(e){
            if ($(this).hasClass('bluebackground')) {
                $(this).innerHTML = 'i';
                $(this).removeClass('bluebackground');
                $(this).parent('.resource').attr('exp', $(this).attr('instances'));
            }
            //If it was not selected before, select.            
            else {
                $(this).innerHTML = 'c';
                $(this).addClass('bluebackground');
                $(this).parent('.resource').attr('exp', $(this).attr('classes'));
            }
            e.stopPropagation();
        });
        $(this).parent('.resource').attr('exp', $(this).attr('instances'));
    });
    //calcuates the facets
    $('._facet').each(function(item){
        $(this).click(function(){
            if ($('.SELECTED').size() != 1) {
                alert("Select JUST 1 set to apply the facets.");
            }
            else {
                if ($('.SELECTED').first().hasClass('resource')) {
                    alert('You can only facet a SET not a RESOURCE.')
                    return;
                }                
                $('.SELECTED').first().crt_facet('default');
            }            
        });
    }); //calcuates the facets
	
    $('._infer').each(function(item){
        $(this).click(function(){
        
            if ($('.SELECTED').size() != 1) {
                alert("Select JUST 1 set to apply the facets.");
            }
            else {
                if ($('.SELECTED').first().hasClass('resource')) {
                    alert('You can only facet a SET not a RESOURCE.')
                    return;
                }
                $('.SELECTED').first().crt_infer();
            }
        });
    });
	
    $('._view').each(function(x){
        $(this).click(function(e){
            ajax_request('/viewer/index?setid=' + $(this).parent('._WINDOW').attr("id"));
        });
    });
	
    $('._object_view').each(function(item){
        $(this).click(function(){        
        
            $(this).parent('._WINDOW').children('.tranparentpanel').first().css({
                display: 'block',
                position: 'absolute',
                width: '100%',
                height: '100%'
            });
            $(this).parent('._WINDOW').crt_refresh('object_view', '');
        });
    });
	
    $('._predicate_view').each(function(item){
        $(this).click(function(){
            $(this).parent('._WINDOW').children('.tranparentpanel').first().css({
                display: 'block',
                position: 'absolute',
                width: '100%',
                height: '100%'
            });
            $(this).parent('._WINDOW').crt_refresh('predicate_view', '');
        });
    });
	
    $('._subject_view').each(function(item){
        $(this).click(function(){
            $(this).parent('._WINDOW').children('.tranparentpanel').first().css({
                display: 'block',
                position: 'absolute',
                width: '100%',
                height: '100%'
            });
            $(this).parents('._WINDOW').first().crt_refresh('subject_view', '');
            
        });
    });
}

////////////////////////////////////////////////////////////////////////////////////////////////////////	
//////////////////////////////WINDOW BEHAVIOURS/////////////////////////////////////////////////////////
function register_ui_window_behaviour(){
    //create a new window with the expression.
    // $('._new').unbind().each(function(view_item){
    //     $(this).on("click", function(){
    //         ajax_create($(this).attr("exp"));
    //     });
    // });
    $('._refresh').each(function(item){
        $(this).on ("click", function(){
            $(this).parent('._WINDOW').crt_refresh('subject_view', '');
        });
    });
    
    //Adds a id to all _WINDOW elements.
    //This is necessary for the ajax_update method know which element should be updated.
    $('._WINDOW').each(function(item){
        $(this).identify();
    });
    //Add window show behaviour to the elements with  _MINIMIZE annotation 
    $('._show').each(function(item){
        $(this).click(function(e){
            $(this).parents('._WINDOW').first().children().each(function(x){
                if (!$(this).hasClass('_NO_MINIMIZE')) {
                    $(this).ui_show();
                }
            });
            e.stopPropagation();
        });
    });
	
    //Add window hide behaviour to the elements with _MINIMIZE annotation
    // $('._hide').each(function(item){
    //     $(this).click(function colapse(){
    //         $(this).parents('._WINDOW').first().children().each(function(x){
    //             if (!$(this).hasClass('_NO_MINIMIZE') && $(this).is(":visible")) {
    //                 $(this).ui_hide();
    //             }
    //         });
    //     });
    // });
    
    $('._expandproperties').each(function(item){
    	
        $(this).click(function(e){
			if($(this).parents('._WINDOW').first().children('.properties').size() == 0) {
				new Item($(this).parent().parent()).render_relations();
			} 
            $(this).parents('._WINDOW').first().children('.properties').each(function(x){
                $(this).ui_show();
            });
            $(this).parents('._WINDOW').first().children('._collapseproperties').show();
            $(this).parents('._WINDOW').first().children('._expandproperties').hide();
            e.stopPropagation();
        });
    });
	
	
    $('._collapseproperties').each(function(item){
		console.log("COLLAPSING: " + this.toString());
        $(this).click(function(e){
            $(this).parents('._WINDOW').first().children('.properties').each(function(x){
                $(this).ui_hide();
            });
            $(this).parents('._WINDOW').first().children('._expandproperties').show();
            $(this).parents('._WINDOW').first().children('._collapseproperties').hide();
            e.stopPropagation();
        });
        
    });
    
    
    //Add window maximize behaviour to the _WINDOW
    $('._maximize').each(function(item){
        $(this).click(function(){
            $(this).parents('._WINDOW').first().addClass('windowmaximized');
        });
    });
	
    $('._minimize').each(function(item){
        $(this).click(function(){
            $(this).parents('._WINDOW').first().removeClass('windowmaximized');
        });
    });
	
    //Add window close behaviour to the elements with _WINDOW annotation	
    $('._remove').each(function(item){
        $(this).click(function(){

            $(this).parents('._WINDOW').first().ui_remove();
        });
    });
	
    $('._close').each(function(item){
        $(this).click(function(){
			
            $(this).parents('._WINDOW').first().ui_close();
        });
    });	
	
    
    //    $('._editable').each(function(item){
    //       new Ajax.InPlaceEditor(item.identify(), '/crud/edit');     
    //    });
    
    //Add the drag and drop behaviour. This allows the object to be repositioned on the screen.
}

function register_tree_selection_behavior(){
	$tree.on("changed.jstree", function(e, data){
		var $node = $("#" + data.node.id);
	    if (!(event.ctrlKey || event.shiftKey)) {
			$(".SELECTED").removeClass("SELECTED");
			$node.addClass("SELECTED");
	    }
	    //When a shift + click event happens
	    else {
			console.log("SHIFT PRESSED " +$node.attr("id") )
	        //If it was selected before, deselect. 
	        if ($node.hasClass('SELECTED')) {
	            $node.removeClass('SELECTED');
	        }
	        //If it was not selected before, select.
	        else {
				console.log("ADDING SELECTION TO: " + $node.attr("id"))
	            $node.addClass('SELECTED');
	        }
	        //If the window is selected, then does not select this element
	        if ($node.parents('._WINDOW.SELECTED').size() > 0) {
	            $node.removeClass('SELECTED');
	        }
	    }
		

	});	
}


function select_page(view, page) {
	$(view).find('.pagination').pagination('drawPage', page);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////SELECTION BEHAVIOURS//////////////////////////////////////////////////////
function register_ui_selection_behaviour(){
    $('.select').each(function(item){
		var that_item = this;
		
        $(that_item).unbind().click(function(event){
			$('._draggable').each(function(){
				if ($(this).data('ui-draggable')){
					$(this).draggable("destroy");
					$(this).resizable("destroy");				
				}
				$(this).draggable({snap: true});
				$(this).resizable();				
			});
			

			if (event.target !== this)
				return
				
            $(that_item).children('.properties').each(function(x){
                if (!$(this).hasClass('_NO_MINIMIZE') && $(this).is(":visible")) {
                    $(this).ui_hide();
                }
            });
            var uri = $(that_item).attr('resource');
            if (uri != null) 
                $('#seachbykeyword').value = uri.replace('<', '').replace('>', '')
            
            
            $(that_item).children('._collapseproperties').hide();
            $(that_item).children('._expandproperties').show();
            //When only click event happens
			 
            if ($(this).altKey) {            
                var uri = $(that_item).attr('resource');
 
                window.open(uri.substring(1, uri.length - 2), '_blank');
				            event.stopPropagation();
				return;
            }
        
            if (!(event.ctrlKey || event.shiftKey)) {
                //remove the selection from all elements on the interface
                $('.SELECTED').removeClass('SELECTED');
                //add selection to this element
                $(that_item).addClass('SELECTED');
            }
            //When a shift + click event happens
            else {
				console.log("SHIFT PRESSED " +$(that_item).attr("id") )
                //If it was selected before, deselect. 
                if ($(that_item).hasClass('SELECTED')) {
                    $(that_item).removeClass('SELECTED');
                }
                //If it was not selected before, select.
                else {
					console.log("ADDING SELECTION TO: " + $(that_item).attr("id"))
                    $(that_item).addClass('SELECTED');
                }
                //If the window is selected, then does not select this element
                if ($(that_item).parents('._WINDOW.SELECTED').size() > 0) {
                    $(that_item).removeClass('SELECTED');
                }
            }
            //Deselect all element selected inside another one.
            $(that_item).children('.SELECTED').removeClass('SELECTED');
			

            //stop the event propagation.
            event.stopPropagation();
        });
    });
    $('._checkboxfacet').each(function(item){
        $(this).click(function(event){
            $(this).crt_dofacet();
        });
    });
}
var paramClassIndex = 0
function new_param_widget(paramName){
	paramClassIndex++
	var param_widget_html = 
	"<div class = \"_WINDOW select param string\" id = \""+paramName+ "\" title = \"Relations\" paramclass = \"Param"+paramClassIndex+"\">"
		+ "<div class = 'expand _NO_MINIMIZE'>"
			+ "<div class ='_collapseproperties' style=\"float:left;\">"
				+ "<span class=\"tool\">-<span class=\"tip\">Hide all selected values.</span></span>"
			+ "</div>"
			+ "<div class= \"_expandproperties\" style=\"float:left;\">"
				+ "<span class=\"tool\">+ <span class=\"tip\">Show selected values for parameter.</span></span>"
			+ "</div>"
		+ "</div>"
		+ "<span class = \"paramname\">" + paramName + "</span>"
		+ "<div id = \"" + paramName + "_values_div\" class = \" _WINDOW paramvalues\"></div>"
	+ "</div>"

	$("#paramsWindow").append(param_widget_html);	

	$("#" + paramName).click(function(e){
		$(".SELECTED").addClass($(this).attr("paramclass"));
		$(this).addClass($(this).attr("paramclass"));
		currentExecution.setParam($(this).attr("id"), $(".SELECTED").attr("id"));
	});	
}

function find_selected_param() {
	if($("#paramsWindow .SELECTED").size() > 0) {
		return $("#paramsWindow .SELECTED")
	} 	
	return null;	
}

function set_param_values(paramName, values){
	var values_div_id = "#"+paramName+"_values_div";
	$(values_div_id).empty();
	for (var param_value in values) {
		add_param_value(paramName, param_value);
	}
}

function add_param_value(paramName, paramvalue) {
	var values_div_id = "#"+paramName+"_values_div";
	var value_div = ""
	+ "<div class = \"select _WINDOW draggable paramvalues\">"
		+ "<span class = \"valuetext\"> "+ paramvalue + "</span>"
	+ "</div>"
	$(values_div_id).append(value_div);
}

function show_empty_param_window() {	
	var param_view_html = 
	"<div id = \"paramsWindow\" class =\"_WINDOW paramwindow\">"
		+ "<div class = \"windowheader _NO_MINIMIZE\" id='resname'>"
			+ "<div class=\"windowtitle\">"
				+ "Param Selection"
			+ "</div>"		
		+ "</div>"
	+ "</div>"
	
	if($('.set').size() > 0) {
		$(param_view_html).insertBefore($('.set').first());
	} else {
		$('body').append(param_view_html);
	}
}

///////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////WINDOW HELPER FUNCTION//////////////////////////
//Create a empty div window and add to the body.
function ui_create_window(){
    var div = document.createElement('div');
    Element.extend(div);
    id = div.identify();
    div.setAttribute("class", "_WINDOW select");
    document.body.insertBefore(div, $('.set').first());
    return id;
}

//Adds a html fragment on the html body.
function ui_add_window(result){
	console.log("adding window");
    var range = document.createRange();
    range.selectNode(document.body);
    var documentFragment = range.createContextualFragment(result);
	if($('.set').length > 0) {
		$(documentFragment).insertAfter('.set');
	} else {
		$(document.body).append(documentFragment);
	}
    
    init_all();
    $('.set').last().hide();
    
    $('.set').last().toggle({
        effect: 'scale',
		direction: "horizontal"
    });
    
}
