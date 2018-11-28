XPLAIN.widgets = XPLAIN.widgets || {}
XPLAIN.states = XPLAIN.states || {}

XPLAIN.widgets.Widget = function(parent, state){
	this.state = state;
	if (this.state){
		this.state.addObserver(this);
	}
	
	this.children = [];
	this.parent = parent;
	if (this.parent) {

		this.parent.children.push(this);
	}
}

XPLAIN.widgets.Widget.prototype = {
	state: null,
	children: [],
	parent: null,
	update: function(eventJson){
		var eventName =  eventJson.event.charAt(0).toUpperCase() + eventJson.event.slice(1);
		if (this["on" + eventName]){
			
			this["on" + eventName].call(this, eventJson);
		}
		this.children.forEach(function(child){

			child.update(eventJson);
		});
	},
	build: function(){
		this.children.forEach(function(child){
			
			child.build()}
			);
	},
	appendChild: function(childWidget){
		this.children.push(childWidget);
		childWidget.parent = this;
	},
	removeChild: function(childWidget){
		this.children.splice(this.children.indexOf(childWidget), 1);
	},
	getContextState: function(){
		if (this.state){
			return this.state;
		} else {
			if (this.parent){
				return this.parent.getContextState();
			}
		}
	}
	
	
}

XPLAIN.states.State = function(){this.observers = []};
XPLAIN.states.State.prototype = {
	observers: [],
	addObserver: function(observer){
		this.observers = this.observers || [];
		debugger;
		this.observers.push(observer);
	},
	notifyStateChange: function(eventJson){
		
		if (this.observers.length) {
			this.observers.forEach(function(observer){observer.update(eventJson)});
		}
	},
	change: function(eventId, updateFunction){
		debugger
		var newStateData = updateFunction.call();
		var eventJson = {event: eventId, data: newStateData, originState: this}
		this.notifyStateChange(eventJson);
	}
}

