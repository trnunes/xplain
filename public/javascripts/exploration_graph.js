var XPAIR = XPAIR || {};
XPAIR.graph = new function(){
	var that = this;
    this.options = {};
		
	this.nodeColor = {border: '#AFAFAF', background: '#AFAFAF', highlight:{border: '#3fe2f5', background: '#3fe2f5'}}

	this.nodes = new vis.DataSet([
	  {id: 1, label: 'START', color: this.nodeColor},
	]);
	this.edges = new vis.DataSet([]);
	this.graph;
	this.editNode = function(data, callback){
	    
		$('#node-label').html(data.label);
		$('#node-saveButton').click(function(){
			data.label = $('#node-label').value;
			//fire ajax request
		});
		$('#node-cancelButton').click(function(){
			clearNodePopUp.bind();
		});
		$('#node-popUp').css('top', data.event.center.y+'px')
		$('#node-popUp').css('left',data.event.center.x+'px' )
		$('#node-popUp').css('display', 'block');
	    
	},
	
	this.clearNodePopUp = function() {
      $('#node-saveButton').onclick = null;
      $('#node-cancelButton').onclick = null;
      $('#node-popUp').css('display', 'none');
    },

    this.cancelNodeEdit = function(callback) {
      this.clearNodePopUp();
    },
	
	this.updateNodeTitle = function(nodeId, title){
		this.nodes.update([{id: nodeId, label: title}])
	},
	
	this.removeSet = function(xsetId){
		
		this.nodes.remove(xsetId);
		edges = this.edges.get({
		  filter: function (item) {
		    return (item.to == xsetId);
		  }
		});

		this.edges.remove(edges);

	},

	this.init = function(){
		var data = {
			nodes: this.nodes,
			edges: this.edges
		};

		var container = $('#graph_view .graph_container')[0]
		this.graph = new vis.Network(container, data, this.options);
	    this.graph.on("click", function (params) {
			debugger;
			console.log(params);

			var $setWindow = $("#" + params.nodes[0] + "._WINDOW");
			$setWindow.ui_show();
			$setWindow.attr("top", "0px");
			$setWindow.attr("left", "0px");
			$setWindow.insertBefore($('#exploration_area .set').first())
			
			// $setWindow.fadeIn();
			$('.SELECTED').removeClass("SELECTED");
			$setWindow.addClass('SELECTED');
			
						// $setWindow.show();
			// $("#exploration_area").css("z-index: 20");
		});	
	},
	this.focus  = function(xsetId){
		this.graph.focus(xsetId);
		
	},
	this.selectSet = function(xsetId){
		this.focus(xsetId);
		this.graph.selectNodes([xsetId]);
	}
	this.addXset = function(xset){
        try {
			
            this.nodes.add({
                id: xset.getId(),
                label: xset.getTitle(),
				color: this.nodeColor
            });
			if(xset.getResultedFrom()){
				for (var i in xset.getResultedFrom()){
					this.edges.add({
						from: xset.getResultedFrom()[i],
						label: xset.getIntention(),
						to: xset.getId(),
						arrows: 'to'
					});
				}
			} else {

				this.edges.add({
					from: 1,
					to: xset.getId(),
					label: xset.getIntention(),
					arrows: 'to'
					
				});
			}
        }
        catch (err) {
            console.log(err);
        }
		XPAIR.currentSession.getProjections(xset.getId())[0].show();
		
	}
	
}

$(document).ready(function(){
	XPAIR.graph.init();
})
