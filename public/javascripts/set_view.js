var XPLAIN = XPLAIN || {};
XPLAIN.widgets = XPLAIN.widgets || {};

XPLAIN.widgets.DefaultSetWidget = function(parent, view){
	XPLAIN.widgets.Widget.call(this, parent, null);
	this.view = view;
}

XPLAIN.widgets.DefaultSetWidget.prototype = Object.create(XPLAIN.widgets.Widget.prototype);

XPLAIN.widgets.DefaultSetWidget.prototype.build = function(){
	//TODO Move the template instantiation back to the server
	
	
	XPLAIN.widgets.Widget.prototype.build.call(this);
	var setJson = this.getContextState().setJson;
	var $view = $(this.view)

	$view.find('._items_area').replaceWith(this.children[0].view);
	
	$view.find('#windowtitlemin').hide();
	
	$view.attr({
		"id": XPLAIN.guid(),
		"data-id": setJson.id,
		"data-resultedFrom": setJson.resultedFrom,
	});
	$view.data(setJson)
	var that = this;
	var thatWidget = this;
	
	$view.find("#size").html(setJson.size + " Items");
	$view.find("#set_title").html(setJson.title);
	$view.find("#titlemin").html(setJson.title);
	$view.find("#set_title").click(function(e){
		e.stopPropagation();
		$view = $(this).parents('._WINDOW');
		var title = "";
		debugger;
		if ($view.find('#set_title').find('input').length > 0){
			title = $view.find('#set_title').find('input').val();
		} else {
			title = $view.find('#set_title').html();
		}
		$view.find("#set_title").html("<input type=\"text\" id=\"set_title_input\">");
		$view.find("#set_title_input").attr("value", title)
		$view.find("#set_title_input").bind("enterKey",function(e){
			
			$view.find("#set_title").html($(this).val());
			$view.find("#titlemin").html($(this).val());
			debugger
			thatWidget.getContextState().setTitle($(this).val());
		});
		$view.find("#set_title_input").focus()
		$view.find("#set_title_input").keyup(function(e){

		    if(e.keyCode == 13){
		        $(this).trigger("enterKey");
		    }
		});
	});
	
	$view.find("#project").click(function(e){
		debugger
		$setview = $(this).parents('._WINDOW');
		var relationsPivot = new Pivot(new Load(thatWidget.getContextState().setJson.id));
		relationsPivot.addRelation(new Relation({item: "relations"}));

		relationsPivot.execute("json", function(data){
			debugger;
			$setview.find("#properties").empty();
			for(var i in data.extension){
				var r = data.extension[i];
				if(!eval(r.inverse)){
					$setview.find("#properties").append("<li><a class=\"v_property\" tabindex=\"-1\" >"+r.id+"</a></li>");
				}
			}
			$setview.find(".v_property").click(function(e){
				var relation = this.text
				that.project(relation, setJson.id);
			});
			
		});

		
	});

	$view.find("#load_ext").click(function(){
		that.getContextState().calculateExtension();


	});

	if (setJson.extension.length > 0) {
		$view.find("#load_ext").remove();

	}
	
	$view.find('._show').hide();
	$view.find('#add_view').click(function(e){
		debugger
		$view.find("#view_options").empty();
		for (var i in setJson.view_options){
			var viewOption = setJson.view_options[i];
			$view.find("#view_options").append("<li><a class=\"v_option\" tabindex=\"-1\" >"+viewOption+"</a></li>");
		}
		
		$view.find(".v_option").click(function(e){
			
			debugger;
			thatWidget.parent.createChildComponent(this.text);
		});
		
	});

	
	var to=false;
	$view.find('.search-input').keyup(function () {
		debugger
      if(to) { 
		  clearTimeout(to); 
	  }
      to = setTimeout(function () {
		  
        var v = $view.find('.search-input').val();
        
		if((v.length > 4) || (!v.length)){
			if(v.length){
				$('#loadwindow').show();
			}
			var eventJson = {event: "keywordSearch", data: v, originState: thatWidget.getContextState()}

			thatWidget.update(eventJson);
		}
        
      }, 250);
    });


	//TODO add init pagination list
	this.init_pagination_list($view, setJson);
	



	this.register_ui_behaviour($view);
	this.view = $view;
	this.html = $view;

	
}

XPLAIN.widgets.DefaultSetWidget.prototype.onCalculateExtension = function(eventJson){
	
	console.log(this.getContextState().setJson)
	debugger
	$(this.view).find("#load_ext").remove();
	this.init_pagination_list(this.view, this.getContextState().setJson);
	$view.find("#size").html(this.getContextState().setJson.size + " Items");
}
	
XPLAIN.widgets.DefaultSetWidget.prototype.setTitle = function(title, $view){
	this.getContextState().setTitle(title);
	
	return title;
}

XPLAIN.widgets.DefaultSetWidget.prototype.onSetTitle = function(eventJson){
	debugger;
	var newTitle = this.getContextState().setJson.title
	$(this.view).find("#set_title").html(newTitle);
	XPLAIN.graph.updateNodeTitle(this.getContextState().setJson.id, newTitle);
}
	//TODO project only in the view that started the request and not in all views
XPLAIN.widgets.DefaultSetWidget.prototype.project = function(relation, setId){
	debugger;
	var that = this;
	new Project(new Load(setId), relation).execute("json", function(data){
		debugger;

		for (var index in that.children){
			var itemsViewController = that.children[index];
			itemsViewController.updateText(data.extension);
		}
	});
}
	
XPLAIN.widgets.DefaultSetWidget.prototype.register_ui_behaviour = function($view){
    //Initialize window behaviour.
    this.register_ui_window_behaviour($view);
    //Initialize de selection behaviour.
    this.register_ui_selection_behaviour($view);
}
	
XPLAIN.widgets.DefaultSetWidget.prototype.register_ui_window_behaviour = function($view){
    //Add window maximize behaviour to the _WINDOW
    $view.find('._show').each(function(item){
        $(this).unbind().click(function(){
			$(this).parents('._WINDOW').first().ui_show();
        });
    });

    $view.find('._hide').each(function(item){
	
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
			
			$window = $(this).parents('._WINDOW');
			var setTitle = $window.find('#set_title').html()
			$window.tooltip({title: setTitle});
			
			//TODO get title from the view instead of a xset object
			
		
			$window.attr('data-original-title', setTitle)

			$window.off("hover").hover(function(){
				$(this).tooltip("show");
			}, function(){$(this).tooltip("hide");});

        });
	
    });

    //Add window close behaviour to the elements with _WINDOW annotation	
    $view.find('._remove').each(function(item){
        $(this).click(function(e){

        	//TODO duplicated code: workspace.js#onDeleteSet()

            $(this).parents('.hideable').first().ui_remove();
            var setToRemove = $(this).parents('._WINDOW').attr("data-id");
        	XPLAIN.graph.removeSet(setToRemove);
            debugger
            if (e){
            	e.stopPropagation();
            }
			
        });
    });

    $view.find('._close').each(function(item){
        $(this).click(function(){
		
            $(this).parents('.hideable').first().ui_close();
        });
    });


}
	
XPLAIN.widgets.DefaultSetWidget.prototype.register_ui_selection_behaviour = function($view){


    $view.unbind().click(function(event){
					
	
		nodeToFocus = ""
		if($(this).hasClass('set')){
			nodeToFocus = $(this).attr("data-id");
		} else {
			nodeToFocus = $(this).parents('._WINDOW').attr("data-id");
		}

        XPLAIN.graph.selectNode(nodeToFocus);
		$('._draggable').each(function(){
			if ($(this).data('ui-draggable')){
				$(this).draggable("destroy");
				$(this).resizable("destroy");				
			}
			$(this).draggable();
			$(this).resizable();				
		});
		
		//TODO figure out a better way to improve the set selection interaction
		var fire_set_select = $(event.target).hasClass('set') || !($(event.target).hasClass('no_set_select') || $(event.target).parents('.no_set_select').length || $(event.target).parents('._items_area').length);
		if(fire_set_select){

			if ($view.hasClass('SELECTED')) {
				$view.removeClass('SELECTED');
			} else {
				$('.SELECTED').removeClass('SELECTED');
				$view.addClass('SELECTED');
			}
			
		}

	

		if (event.target !== this)
			return;
		
        $view.children('.properties').each(function(x){
            if (!$(this).hasClass('_NO_MINIMIZE') && $(this).is(":visible")) {
                $(this).ui_hide();
            }
        });
        var uri = $view.attr('resource');
        if (uri != null) 
            $('#seachbykeyword').value = uri.replace('<', '').replace('>', '')
    
    
        $view.children('._collapseproperties').hide();
        $view.children('._expandproperties').show();
        //When only click event happens
	 
        if ($(this).altKey) {            
            var uri = $view.attr('resource');

            window.open(uri.substring(1, uri.length - 2), '_blank');
			            event.stopPropagation();
			return;
        }
		
        if (!(event.ctrlKey || event.shiftKey)) {
            //remove the selection from all elements on the interface
            $('.SELECTED').removeClass('SELECTED');
            //add selection to this element
            $view.addClass('SELECTED');
        }
        else if(event.shiftKey){
			console.log("SHIFT PRESSED " +$view.attr("id") )
            //If it was selected before, deselect. 
            if ($view.hasClass('SELECTED')) {
                $view.removeClass('SELECTED');
            }
            //If it was not selected before, select.
            else {
				console.log("ADDING SELECTION TO: " + $view.attr("id"))
                $view.addClass('SELECTED');
            }
            //If the window is selected, then does not select this element
            if ($view.parents('._WINDOW.SELECTED').size() > 0) {
                $view.removeClass('SELECTED');
            }
        } else if(event.ctrlKey){
			console.log("controll pressed")
        	$view.addClass('SELECTED');
        }
        //Deselect all element selected inside another one.
        $view.children('.SELECTED').removeClass('SELECTED');
	

        //stop the event propagation.
        event.stopPropagation();
    });

}
	
XPLAIN.widgets.DefaultSetWidget.prototype.init_pagination_list = function($view, setJson){
	var thisController = this;

	first_page = $view.find(".pagination").children()[1];
	
	if(setJson.pages_count <= 1){
		$view.find(".pagination_div").hide();
	} else {
		$view.find(".pagination_div").show()
		var pagesList = []
		if(setJson.pages_count >= 5){
			for(var i=2; i<=5; i++){

				page_view = $(first_page).clone();
				$(page_view).find("a").text(i);
				if(i == 3){
					$(page_view).find("a").text("...");
				} else if(i == 4){
					$(page_view).find("a").text(setJson.pages_count - 1);
				} else if(i == 5){
					$(page_view).find("a").text(setJson.pages_count);
				}				
				pagesList.push(page_view)

			}

		} else{
			for (var i=2; i <= setJson.pages_count; i++){
				
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
		
		$view.find(".pagination li a").click(function(e){
			

			var pageNumber;
			var $setView = $(this).parents('.set');
			var activePageText = $(this).parents('li').siblings('.pg_active').text();
			if($(this).attr("aria-label") == "Next"){
				pageNumber = parseInt(activePageText) + 1;
				debugger;
				if(parseInt(activePageText) == $setView.data('pages_count')){
					return;
				}
				
				if($(this).parents("ul").find("li a").filter(function(){return $(this).text() == ""+pageNumber}).length == 0){
					$($setView.find(".pagination li a")[1]).html(pageNumber - 1);
					$($setView.find(".pagination li a")[2]).html(pageNumber);
				}
			}else if($(this).attr("aria-label") == "Previous"){
				debugger;
				if(parseInt(activePageText) == 1){
					return;
				}
				
				pageNumber = parseInt(activePageText) - 1
				if(pageNumber < setJson.pages_count - 2){
					$($setView.find(".pagination li a")[1]).html(pageNumber);
					$($setView.find(".pagination li a")[2]).html(pageNumber+1);
				}
				
			} else {
				if($(this).text() != "..."){
					activePageText = $(this).text()
					pageNumber = parseInt(activePageText);
				}
			}	

				
			thisController.renderPage($setView.attr('id'), pageNumber);
			
			
			$setView.find(".pagination li").removeClass("pg_active")
			$(this).parents("ul").find("li a").filter(function(){return $(this).text() == ""+pageNumber}).parents('li').addClass("pg_active")
				
		});
		$($view.find(".pagination li")[1]).addClass("pg_active");
	}

}
	
XPLAIN.widgets.DefaultSetWidget.prototype.renderPage = function(viewId, pageNumber){
	this.getContextState().setPage(pageNumber);
}