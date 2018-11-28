XPLAIN.widgets = XPLAIN.widgets || {}
XPLAIN.states = XPLAIN.states || {}

XPLAIN.widgets.SetWidget = function(parent, setState){
	XPLAIN.widgets.Widget.call(this, parent, setState);
}

XPLAIN.widgets.SetWidget.prototype = Object.create(XPLAIN.widgets.Widget.prototype);

XPLAIN.widgets.SetWidget.prototype.build = function(){
	XPLAIN.widgets.Widget.prototype.build.call(this);
}

XPLAIN.widgets.SetWidget.prototype.createChildComponent = function(componentName){
	var thisWidget = this;
	XPLAIN.AjaxHelper.get("/session/render_view.json?view=" + componentName + "&set=" + this.state.setJson.id, "json", function(viewData){
		debugger
		
		var concreteSetView = $(viewData.html);
		var extensionView = $(viewData.html).find('.extension_view');
	
		var setWidget = new XPLAIN.widgets[capitalizeFirstLetter(concreteSetView.attr('id'))](thisWidget, concreteSetView);
		if (extensionView){
			var extensionWidget = new XPLAIN.widgets[capitalizeFirstLetter(extensionView.attr('id'))](setWidget, extensionView);
		}
		
		setWidget.build();
		
		XPLAIN.activeWorkspaceWidget.addWidgetToView(setWidget);
	});
	
}


XPLAIN.states.SetState = function(setJson){

	XPLAIN.states.State.call(this);
	this.setJson = setJson
	this.items = {};
}
XPLAIN.states.SetState.prototype = Object.create(XPLAIN.states.State.prototype)

XPLAIN.states.SetState.prototype.items = [],

XPLAIN.states.SetState.prototype.addItemFromJson = function(setJson){
	
}

XPLAIN.states.SetState.prototype.addItemState = function(itemState){
	this.change('addItem', function(){
		this.items.push(itemState);
		return itemState;
	});
}

XPLAIN.states.SetState.prototype.setTitle = function(newTitle) {
	if (newTitle == this.setJson.title) {
		return;
	}

	var titleUpdateExpr = 'Xplain::ResultSet.load("' + this.setJson.id + '").title = "' + newTitle + '"';
	that = this;
	debugger;
	XPLAIN.AjaxHelper.get("/session/execute_update?update=" + titleUpdateExpr, "json", function(data){
		that.change('setTitle', function(){
			debugger;
			that.setJson.title = newTitle;
			return newTitle;
		});
	});
}

XPLAIN.states.SetState.prototype.setPage = function(page){
	that = this;
	XPLAIN.AjaxHelper.get("/session/render_page.json?set=" + that.setJson.id + "&page=" + page, "json", function(data){
		that.change('pageChange', function(){
			that.setJson.extension = data.extension;
		});
	});
}

function capitalizeFirstLetter(string) {
    return string.charAt(0).toUpperCase() + string.slice(1);
}

XPLAIN.widgets.createView = function(parentWidget, setJson){
	debugger
	var state = new XPLAIN.states.SetState(setJson);
	var setViewId = $(setJson.view).attr('id');
	var extensionViewId = $(setJson.view).find('.extension_view').attr('id');
	var itemViewId = $(setJson.view).find('.extension_view .item_view').attr('id');
	
	var setWidget = new XPLAIN.widgets[capitalizeFirstLetter(setViewId)](parentWidget, setJson.view);
	if (extensionViewId){
		var extensionWidget = new XPLAIN.widgets[capitalizeFirstLetter(extensionViewId)](setWidget, $(setJson.view).find('.extension_view'));
	}
	
	return setWidget;
}