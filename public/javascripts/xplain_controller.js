/**
 * This code implements all the user interface behaviour of Xplain
 * @author Thiago Nunes
 */
//This method should be executed when the window load.
//Plug the behaviour to the annoted elements.
var XPLAIN = XPLAIN || {}

XPLAIN = {
	activeWorkspaceState: null,
	activeWorkspaceWidget: null,
	initDefaultWorkspace: function(){
		//TODO develop the save and load workspace state
		var workspace = new XPLAIN.states.WorkspaceState();
		var workspaceWidget = new XPLAIN.widgets.DefaultWorkspaceWidget(workspace);
		
		workspaceWidget.build();
		this.activeWorkspaceWidget = workspaceWidget;
		this.activeWorkspaceState = workspace;
		
	},
	
	guid: function() {
	  function s4() {
	    return Math.floor((1 + Math.random()) * 0x10000)
	      .toString(16)
	      .substring(1);
	  }
	  return s4() + s4() + '-' + s4() + '-' + s4() + '-' +
	    s4() + '-' + s4() + s4() + s4();
	}
	
}