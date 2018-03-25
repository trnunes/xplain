
XPLAIN.widgets.Accordion = function(parent, view){
	XPLAIN.widgets.Widget.call(this, parent, null);
	debugger
	this.view = view;
}

XPLAIN.widgets.Accordion.prototype = Object.create(XPLAIN.widgets.Widget.prototype);

XPLAIN.widgets.Accordion.prototype.build = function(){
	XPLAIN.widgets.Widget.prototype.build.call(this);
}
		
