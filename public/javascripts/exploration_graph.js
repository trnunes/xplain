var XPAIR = XPAIR || {};
XPAIR.graph = new function(){
	this.nodes = new vis.DataSet([
	  {id: 1, label: 'START'},
	]);
	this.edges = new vis.DataSet([]);
	this.graph;
	this.init = function(){
		var data = {
			nodes: this.nodes,
			edges: this.edges
		};
		var options = {};
		var container = document.getElementById('graph_area');
		this.graph = new vis.Network(container, data, options);
	    this.graph.on("doubleClick", function (params) {
			
			console.log(params);
			var $setWindow = $("#" + params.nodes[0] + "._WINDOW");
			
			$setWindow.css("top", '0px');
			$setWindow.css("left", '0px');
			$setWindow.css("position", 'absolute');
			$setWindow.animate({top: params.event.center.y, left: params.event.center.x});
			$setWindow.fadeIn();
						// $setWindow.show();
			// $("#exploration_area").css("z-index: 20");
		});	
	},
	this.addXset = function(xset){
        // try {
            this.nodes.add({
                id: xset.getId(),
                label: xset.getIntention()
            });
			if(xset.getResultedFrom()){
				for (var i in xset.getResultedFrom()){
					this.edges.add({
						from: xset.getResultedFrom()[i],
						to: xset.getId()
					});
				}
			} else {
				this.edges.add({
					from: 1,
					to: xset.getId()
				});			
			}
			
        // }
        // catch (err) {
        //     alert(err);
        // }
		
	}
	
}

$(document).ready(function(){
	XPAIR.graph.init();
})
