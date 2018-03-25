var XPLAIN = XPLAIN || {};
XPLAIN.graph = new function(){
	var that = this;
	
    this.options = { 
        physics: {
          stabilization: false
        },
        configure: {
          filter:function (option, path) {
			  // debugger;
            if ((path.indexOf('physics') !== -1) && (option == 'enabled')) {
              return true;
            }
            return false;
          },
		  showButton: false
        },
	  };
		
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
	
	this.removeSet = function(setId){
		that = this;		
		this.nodes.remove(setId);

		var toEdges = this.edges.get({
		  filter: function (item) {
		    return (item.to == setId);
		  }
		});
		var fromEdges = this.edges.get({
		  filter: function (item) {
		    return (item.from == setId);
		  }
		});

		fromEdges.forEach(function(edge){
			that.edges.add({
				from: 1,
				to: edge.to,
				label: edge.label,
				arrows: 'to'
			});
		});
		this.edges.remove(toEdges);
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
	this.addSet = function(setJson){
        try {
	        this.nodes.add({
                id: setJson.id,
                label: setJson.title,
				color: this.nodeColor
            });
			debugger;
			if (setJson.resultedFrom){
				for (var i in setJson.resultedFrom){
					this.edges.add({
						from: setJson.resultedFrom[i],
						label: setJson.intention,
						to: setJson.id,
						arrows: 'to'
					});
				}
			} else {

				this.edges.add({
					from: 1,
					to: setJson.id,
					label: setJson.intention,
					arrows: 'to'
				});
			}
        }
        catch (err) {
            console.log(err);
        }
	}
}

$(document).ready(function(){
	XPLAIN.graph.init();
})
