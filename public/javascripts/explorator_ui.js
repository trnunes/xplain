/**
 * This code implements all the user interface behaviour of explorator
 * @author samuraraujo
 */

var context_menus_hash = new Hashtable();
//Add global ui methods to the elements
jQuery.fn.extend({
    //Hide an element
    ui_hide: function(item){
		// $(this).hide("blind", {direction: "up"}, 1000);
    },
    //Show an element
    ui_show: function(){
		$(this).find('._show').hide()
		
		$(this).find('._hide').show();
		
        $(this).first().attr("style", "");
		debugger;
		if(!$(this).find("._NO_MINIMIZE").next().is(":visible")){
			$(this).find("._NO_MINIMIZE").nextAll().slideToggle();
		}
		$(this).find('#windowtitlemin').hide();
		$(this).find('#windowtitlemax').show();
		$(this).css("top", "5px");
		$(this).find(".btn-group").show();
		$(this).css("width", "350px");
		$(this).css("height", "450px");
		$(this).appendTo("#exploration_area");
		

    	
    }, //maximize a window
	
    //remove an element
    ui_remove: function(item){
        //removes the element from the model and replace the interface with a new one.

        $(this).fadeOut();
		XPLAIN.graph.removeSet($(this).attr("id"));
		
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
	
	register_modal_actions();
	
	registerToolbarBehavior();
}

function registerToolbarBehavior(){
	$('.dropdown-submenu a.test').on("click", function(e){

		$('.dropdown-submenu').children('ul').hide()
	    $(this).next('ul').toggle();
		e.stopPropagation();
        e.preventDefault();
     });
}

function register_modal_actions(){
	
	

	
	
	// $("#facetModal").on("hide.bs.modal", function () {
	// 	if ($("#facetModal .modal-body").hasClass("jstree")) {
	// 	  $("#facetModal .modal-body").jstree("destroy");
	// 	}
	// 	$('#relation_input input').val('');
	// 	$('#relation_checkbox').prop('checked', false);;
	// 	$('#select_comparator').val('=');
	// 	// $("#selected_path_header").nextAll().remove();
	// 	// $("#selected_path_header").remove();
	// 	// 	    $("#pivot_group .dropdown-menu").append("<li id=\"selected_path_header\" class=\"dropdown-header\">Selected Path</li>");
	// 	//
	// 	// for(var i in parameters.get("relations")){
	// 	// 	$("#pivot_group .dropdown-menu").append("<li class=\"dropdown-header\">"+$(parameters.get("B")).attr("item")+"</li>");
	// 	// }
	//
	// });
	
}

function clearFacetModal(){
	$('.filters').empty();
	$("#facetModal .modal-body").hide();
	// $("#facetModal .values_select").empty();
	$('#relation_checkbox').prop('checked', false);
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
	$(".help_btn").unbind().click(function(){
		if ($('#' + $(this).attr("operation") + "_help").is(':empty')){
			XPLAIN.AjaxHelper.get("/session/help?operation=" + $(this).attr("operation"));
		}else{
			$('#' + $(this).attr("operation") + "_help").empty();
			
		}
		
	});
	
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
    // $('._show').each(function(item){
    //     $(this).click(function(e){
    //         $(this).parents('._WINDOW').first().children().each(function(x){
    //             if (!$(this).hasClass('_NO_MINIMIZE')) {
    //                 $(this).ui_show();
    //             }
    //         });
    //         e.stopPropagation();
    //     });
    // });
    //
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
			$(this).parents('._WINDOW').css("top", "0px");
            $(this).parents('._WINDOW').first().children('._expandproperties').show();
            $(this).parents('._WINDOW').first().children('._collapseproperties').hide();
			
            e.stopPropagation();
        });
        
    });
    
    
    //Add window maximize behaviour to the _WINDOW
    $('._show').each(function(item){
        $(this).unbind().click(function(){
			$(this).parents('._WINDOW').first().ui_show();
			// $(this).hide();
			//
			// $(this).parents('._WINDOW').find('._hide').show();
			//
			//             $(this).parents('._WINDOW').first().attr("style", "");
			// $(this).parents('._WINDOW').find("._NO_MINIMIZE").nextAll().slideToggle();
			// $(this).parents('._WINDOW').css("top", "75px");
			// $(this).parents('._WINDOW').find(".btn-group").show();
			// $(this).parents('._WINDOW').css("width", "350px");
			// $(this).parents('._WINDOW').appendTo("#exploration_area");
        });
    });
	
    $('._hide').each(function(item){
		
        $(this).unbind().click(function(){
			$(this).hide();
			$(this).parents('.hideable').find('._show').show();
			$(this).parents('.hideable').first().attr("style", "");
            $(this).parents('.hideable').find("._NO_MINIMIZE").nextAll().slideToggle();
			$(this).parents('.hideable').find('#windowtitlemin').show();
			$(this).parents('.hideable').find('#windowtitlemax').hide();
			$(this).parents('.hideable').css("top", "0px");
			$(this).parents('.hideable').css("width", "150px");
			$(this).parents('.hideable').css("height", "50px");
			$(this).parents('.hideable').find(".btn-group").hide();
			$(this).parents('.hideable').appendTo(".container");
			debugger;
			var xset = XPLAIN.currentSession.getSet($(this).parents(".set").attr('id'));
			$("._WINDOW").tooltip({title: xset.getTitle()});
			
			$("#" + xset.getId()).attr('data-original-title', xset.getTitle())

			$("._WINDOW").off("hover").hover(function(){
				$(this).tooltip("show");
			}, function(){$(this).tooltip("hide");});

        });
		
    });
	
    //Add window close behaviour to the elements with _WINDOW annotation	
    $('._remove').each(function(item){
        $(this).click(function(e){

            $(this).parents('.hideable').first().ui_remove();
			e.stopPropagation();
        });
    });
	
    $('._close').each(function(item){
        $(this).click(function(){
			
            $(this).parents('.hideable').first().ui_close();
        });
    });	
	
    
    //    $('._editable').each(function(item){
    //       new Ajax.InPlaceEditor(item.identify(), '/crud/edit');     
    //    });
    
    //Add the drag and drop behaviour. This allows the object to be repositioned on the screen.
}



function select_page(view, page) {
	$(view).find('.pagination').pagination('drawPage', page);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////SELECTION BEHAVIOURS//////////////////////////////////////////////////////
function register_ui_selection_behaviour2(){
	$('.select').unbind().each(function(){
		$(this).unbind().click(function(event){
			var $currentSelection = $('.SELECTED');
			if(event.shiftKey){
				if($currentSelection.length){
					var isBeforeCurrentSelection = ($currentSelection.prevAll("#" + $(this).attr("id")).length > 0)
					if(isBeforeCurrentSelection){
						$currentSelection.prevUntil($(this)).addClass("SELECTED");
					} else {
						$currentSelection.nextUntil($(this)).addClass("SELECTED");
					}
				}
				
			} else if(event.ctrlKey){
				$(this).addClass("SELECTED");
				
			} else{
				$(this).removeClass("SELECTED");
				$(this).addClass("SELECTED");
			}
		});
	});
}

function register_ui_selection_behaviour(){
	
    $('.select').each(function(item){
		var that_item = this;

        $(that_item).unbind().click(function(event){
			
			nodeToFocus = ""
			if($(this).hasClass('set')){
				nodeToFocus = $(this).attr("id");
			} else {
				nodeToFocus = $(this).parents('._WINDOW').attr("id");
			}
			
			XPLAIN.graph.selectSet(nodeToFocus);
			$('._draggable').each(function(){
				if ($(this).data('ui-draggable')){
					$(this).draggable("destroy");
					$(this).resizable("destroy");				
				}
				$(this).draggable();
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
			debugger;
            if (!(event.ctrlKey || event.shiftKey)) {
                //remove the selection from all elements on the interface
                $('.SELECTED').removeClass('SELECTED');
                //add selection to this element
                $(that_item).addClass('SELECTED');
            }
            else if(event.shiftKey){
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
            } else if(event.ctrlKey){
				console.log("controll pressed")
            	$(that_item).addClass('SELECTED');
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
