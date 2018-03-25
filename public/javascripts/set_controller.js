XPLAIN.SetController = {
	
	appendToWorkspace: function(setJson){
		//TODO implement!
		XPLAIN.widgets.createView(setJson, setJson.componentName);
		XPLAIN.graph.addSet(setJson);
	},
	
	initializeView: function(viewId){
		
		//TODO implement delegating to the respective view class
		
	},
	
	getAllSetsIdsAndTitles: function(){
		return $('.set').not('#DefaultSetView').map(function(){return {id: this.id, title: $(this).find('#set_title').html()}});
	},
	
	getResultedFrom: function(setId){
		var resultedFrom = $($('[data-id='+ setId + ']')[0]).data('resultedFrom');
		return resultedFrom;
	},
	
	getExtension: function(setId){
		return $($('[data-id=' + setId  + ']')[0]).data('extension');
	},
	
	getTitle: function(setId){
		return $('[data-id=' + setId + ']').data('title');
	},
	getInputSets: function(setId){
		
		return $('[data-resultedFrom='+setId+ ']').map(function(){$(this).data('title');});
	}
	
}