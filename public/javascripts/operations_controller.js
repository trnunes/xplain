var currentExecution = null;

function Execution(operation_id) {
	
	this.operation = operation_id
    var paramsHash = new Hashtable();
	var currentParam = null;
	var that = this;
	this.addParamValue = function(param, value) {
		if(paramsHash.containsKey(param)) {
			paramsHash.get(param).push(value)
		} else {
			paramsHash.put(param, [value])
		}
	};
	
	this.startParamSetup = function(param_id) {
		currentParam = param_id;
		paramsHash.put(currentParam, []);
	};
	
	this.addValueForCurrentParam = function(paramValue) {
		that.addParamValue(currentParam, paramValue);
	};

    this.getOperation = function () {
        return this.operation;
    };
	
	this.log = function(){
		var executionString = ""
		console.log(this.operation + ":");
		paramsHash.each(function(param, values){
			console.log("	" + param.toString());
			console.log("		" + values.toString());
		});	
	};
	
	this.execute = function(){
		
	}	
};

function Session(session_id){
	this.data = {
		id: session_id, 
		sets: []
	};
	this.sets = new Hashtable();
	this.add_set = function(xset) {
		this.sets.put(xset.id(), xset);
		this.data["sets"].push(xset); 
	};
	
	this.find_set = function(xset_id) {
		return this.sets.get(xset_id);
	};
};

function Item(item_view){
	this.view = item_view
	var this_item = this;

	this.getView = function() {
		return this.view
	}
	this.id = function() {
		return $(item_view).attr("id")
	}
	
	this.render_relations = function() {

		$.ajax(	{			
			type: "GET",
			url: "/session/relations?id="+this_item.id(),
			data_type: "script",
			success: function(data, status, jqrequest) {

				
				$('._items_area').jstree("create_node", [this_item.getView(),returnedRelationsDiv, "first"]);
				init_all();
			}
		});		
	}
};

function Xset() {
	this.data = { 
		items: [],
		relations: {}
	};	
	
	this.id = function() {
		return this.data["id"];
	}
	
	this.set_id = function(id) {
		this.data["id"] = id; 
	};
	
	this.set_intention = function(itention) {
		this.data["intention"] = intention;
	};
	
	this._set_extension = function(extension) {
		this.data["extension"] = extension;
	};
	
	this.add_item = function(item) {
		this.data["items"].push(item);
	};
	this.set_view = function(view) {
		this.view = view;
		
		var this_controller = this;

		$(this.view).find('._image_view').each(function(item){
			$(this).click(function(event){
				$(this_controller.view).find("._items_area").first().empty();
				$(this_controller.view).find("._items_area").first().append(this_controller.image_view);
					
			});
		});
		
		$(this.view).find('._relation_view').each(function(item){
			$(this).click(function(event){
				ajax_renderdomain(this_controller.id());
					
			});
		});		
	};
	this.set_image_view = function(view) {
		this.image_view = view;
	};
	this.show_relations_view = function() {
		$(this.view).find("._items_area").first().empty();
		$(this.view).find("._items_area").first().append(this.relations_view);
	};
	this.set_relations_view = function(view) {
		this.relations_view = view;
	};	
}

function newExecution(operationId){
	console.log("EXECUTION FOR: " + operationId.toString());
	currentExecution = new Execution(operationId);
	renderParamSelectionView(operationId);
};

function paramSelected(paramId){

	currentExecution.startParamSetup(paramId);
	currentExecution.log();
};

function paramValueSelected(valueId){
	currentExecution.addValueForCurrentParam(valueId);
	currentExecution.log();
};

function clear_param_selection(){
	$(".Selected").each(function(){
		$(this).removeClass("Selected")
	});
	$(".ParamSelected").each(function(){
		$(this).removeClass("ParamSelected")
	});
}

function renderParamSelectionView(operationId){
	if (operationId === "refine") {
		render_refine_partial();
	} else if (operationId === "pivot") {
		
	} else if (operationId === "map") {
		
	} else if (operationId === "group") {
		
	} else if (operationId === "find_path") {
		
	}
	
};

function operation_activated(){
	params_hash.put("operation", $(this))
}


function setup_operation_handlers(){
	$("#refine_action").click(function(e){
		var refine_params_bar = "<%= j render(:partial => 'layouts/params_refine') %>"
		$("#params_side_bar").empty()
		$("#params_side_bar").append(refine_params_bar)
	
	});
	
	$("#pivot_action").click(function(e){
		var pivot_params_bar = "<%= j render(:partial => 'layouts/params_pivot') %>"
		$("#params_side_bar").empty()
		$("#params_side_bar").append(refine_params_bar)
	
	});
	
	$("#group_action").click(function(e){
		var group_params_bar = ""
		$("#params_side_bar").empty()
		$("#params_side_bar").append(group_params_bar)		
	});
	
	
	
}
