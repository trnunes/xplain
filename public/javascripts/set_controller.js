XPLAIN.SetController = {
	
	appendToWorkspace: function(setJson){
		//TODO implement!
		XPLAIN.widgets.createView(setJson, setJson.componentName);
		debugger;
		XPLAIN.graph.addSet(setJson);
	},
	
	initializeView: function(viewId){
		
		//TODO implement delegating to the respective view class
		
	},
	
	getAllSetsIdsAndTitles: function(){
		return $('.set').not('#DefaultSetView').map(function(){return {id: this.id, title: $(this).find('#set_title').html()}});
	},
	
	getResultedFrom: function(setId){
		var resultedFrom = $($('[data-id="'+ setId + '"]')[0]).data('resultedFrom');
		return resultedFrom;
	},
	
	getExtension: function(setId){
		return $($('[data-id="' + setId  + '"]')[0]).data('extension');
	},
	
	getTitle: function(setId){
		return $('[data-id="' + setId + '"]').data('title');
	},
	
	getInputSets: function(setId){
		
		return $('[data-resultedFrom="'+setId+ '"]').map(function(){$(this).data('title');});
	},
		
    countLevels: function(setId){
        var extension = this.getExtension(setId);        
        var rootNode = {children: extension};
        return this.nodeHeight(rootNode) - 1;
    },
        
    nodeHeight: function(node){
        
        var tallestChildHeight = 0;

        if (node.children){
            for (var c in node.children){
                var childHeight = this.nodeHeight(node.children[c]);
                
                if (childHeight > tallestChildHeight){
                    tallestChildHeight = childHeight;
                }
            }
        }
        return tallestChildHeight + 1;      
    },
    
    getLeaves: function(setId){
        var extension = this.getExtension(setId);
        return this.getLeavesFromExtension(extension);
    },
    
    getLeavesFromExtension: function(extension){
        var leaves = [];
        for (var i in extension){
            this.nodeLeaves(extension[i], leaves);
        }
        return leaves;  
    },
    
    nodeLeaves: function(node, leaves){
        if (!node.children){
            leaves.push(node);
        } else{
            for (var i in node.children){
                this.nodeLeaves(node.children[i], leaves);
            }            
        }
    },
    
}