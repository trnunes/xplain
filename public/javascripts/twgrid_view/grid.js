
XPLAIN.widgets.Grid = function(parent, view){
	XPLAIN.widgets.Widget.call(this, parent, null);
	this.view = view;
}

XPLAIN.widgets.Grid.prototype = Object.create(XPLAIN.widgets.Widget.prototype);

XPLAIN.widgets.Grid.prototype.build = function(){
	XPLAIN.widgets.Widget.prototype.build.call(this);
}
		
