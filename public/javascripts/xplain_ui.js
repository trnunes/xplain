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

function register_workspace_actions(){
	register_help_action();
};

function register_help_action(){
	$(".help_btn").unbind().click(function(){
		if ($('#' + $(this).attr("operation") + "_help").is(':empty')){
			XPLAIN.AjaxHelper.get("/session/help?operation=" + $(this).attr("operation"));
		}else{
			$('#' + $(this).attr("operation") + "_help").empty();
		
		}
	
	});
}


//This method should be executed when the window load.
//Plug the behaviour to the annoted elements.
