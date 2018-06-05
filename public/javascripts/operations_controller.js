
var XPLAIN = XPLAIN || {};
XPLAIN = {
	currentOperation: null,
	currentSession: null,
	getType: function(f){
		return f.constructor.name;
	},
	Operations: {
		pivot: "pivot",
		refine: "refine",
		group: "group",
		map: "map",
		merge: "merge",
		findPath: "findPath"
	},	
	addParameter: function(parameterId, $view){
		parameters.put(parameterId, $view);
		$view.addClass(parameterId);
		$(".SELECTED").removeClass("SELECTED");
	},
	calculate: function(expression){
		new Expression(expression).execute("json");
	},
	generateExpressionFromSelection: function($selection){
		var unionsHash = new Hashtable();
		var setUnions = []
		$selection.each(function(){
			if ($(this).hasClass("set")){
				setUnions.push(new Load($(this).attr("id")));
			} else {
				var selectedItemSet = $(this).attr("set");
				var selectedItemId = $(this).attr("item");

				if(!unionsHash.containsKey(selectedItemSet)){
					unionsHash.put(selectedItemSet, []);
				}
				unionsHash.get(selectedItemSet).push(selectedItemId)				
			}
		});
		var operations = []
		for (var i in unionsHash.keys()) {
			var setId = unionsHash.keys()[i];
			var selection = unionsHash.get(setId);
			operations.push(new Select(new Load(setId), selection))
		}
		for (var i in setUnions){
			operations.push(setUnions[i]);
		}
		
		if (operations.length > 1){
			return new Union(selectOperations);	
		}else{
			return operations[0];
		}	
	},
		
}


//TODO CHANGE TO XsetController 
XPLAIN.Xset = function(data, operation){	

	this.$view = null;
	var this_set = this;
	this.generates = [];
	this.observers = [];
	this.generatedByOperation = operation
	this.itemsHash = new Hashtable();
	this.page = 1;
	this.previousPage = 1;
	this.intention = null

	this.setIntention = function(intention){
		this.intention = intention;
	},
	
	this.levelChangeListener = null;
	
	this.setData = function(data){
		this.data = data;
		if(this.data.resultedFrom){
			var resultedFromSet = XPLAIN.currentSession.getSet(this.data.resultedFrom);
			if(resultedFromSet){
				resultedFromSet.addGenerates(this);
			}
		}
	},
	
	this.setData(data);
	
	this.isMultilevel = function(){
		if(!this.isEmpty()){
			return this.data.extension[0].children;
		}
		
		
		return false;
	},
	
	
	
	
	this.addGenerates = function(generatedSet){
		this.generates.push(generatedSet);
	},
	
	this.getGenerates = function(){
		return this.generates;
	},
	
	//TODO move to adapter
	this.populateItemsHash = function(){
		var obj = this.data.extension;

		for(var i in obj){

			var item = obj[i]
			if(item.type) {
				this_set.itemsHash.put(item.id, item);
			}
			
			var children = item.children || [];
			
			while(children.length > 0){
				var next_children = []
				children.forEach(function(child){ 

					if(child.type) {
						this_set.itemsHash.put(child.id, child);
						if(child.children) {
							child.children.forEach(function(item){

								next_children.push(item);
							});
						}
					}
				});
				children = next_children;
			}
		}
	},
	
	this.populateItemsHash();
	
	this.getView = function(){
		
		if (this.$view == null){
			this.createEmptyView();
		}
		return this.$view;
	},
	
	this.addObserver = function(observer){
		this.observers.push(observer);
	},
	this.notify = function(newData, event){
		for(var i in this.observers) {
			this.observers[i].update(this, newData, event);
		}	
	},
	
	this.leaves = function(){
		var itemsHash = new Hashtable();
		debugger;
		this.data.extension.forEach(function(item){
			this_set.getLeafNodes(itemsHash, item);
		});
		return items.values();
	},
	
	this.getLeafNodes = function(leafNodes, obj){
		console.log(obj.children)
	    if(obj.children){
	        obj.children.forEach(function(child){this_set.getLeafNodes(leafNodes,child)});
	    } else{
			console.log("leaf: ", obj);
	        leafNodes.put(obj.id, obj);
	    }
	},
	
	this.registerLevelChangeListener = function(listener){
		this.levelChangeListener = listener;
		this.getView().find('#select_levels_list input[type=radio]').each(function(){
			$(this).unbind().change(function(event){				
				listener(parseInt(this.value));
			})
		});
	},
	
	this.getLevel = function(level, callback){
		var levelUrl = "/session/get_level.json?set="+this.getId()+"&level="+ level
		XPLAIN.AjaxHelper.get(levelUrl, "json", callback);		
	},
	
	this.updateLevelsCount = function(levelsCount){
		var first_level_project = this.$view.find("#project_levels_list").children()[0]
		var first_level_select = this.$view.find("#select_levels_list").children()[0]
 
		$(first_level_select).nextAll().remove();
		$(first_level_project).nextAll().remove();
		for(var i=1; i < levelsCount; i++){
			level_view = $(first_level).clone()
			level_view.find("label").html("<input type=\"radio\" name=\"filterradio\" class=\"param\" param=\"filter\" param_value=\"equals\" value=\""+(i+1)+"\"> Level" + (i+1));
			this.$view.find(".levels_list").append(level_view);
		}
		if(this.levelChangeListener != null){
			this.registerLevelChangeListener(this.levelChangeListener);
		}
		this.registerProjectBehavior();
	},
	
	this.registerProjectBehavior = function(){

		this.$view.find('#project_levels_list input[type=radio]').each(function(){
			$(this).unbind().change(function(event){				
				var setId = $(this).parents('._WINDOW').attr("id");
				flatten = new Flatten(new Load(setId), parseInt(this.value));
				flatten.execute('json', function(data){
					var flattened_set = new XPLAIN.Xset(data.set);
					// flattened_set.replace(setId);
					var xsetAdapter = new XPLAIN.adapters.JstreeAdapter(new XPLAIN.Xset(data.set));
					new XPLAIN.views.Jstree(xsetAdapter).show();				
				});
			})
		});
	},
	
	this.replace = function(setId){
		$("#" + setId).replaceWith(this.$view);
	},
	
	this.init_pagination_list = function(){
		first_page = this.$view.find(".pagination").children()[1];
		console.log(this.data.pages_count)
		if(this.data.pages_count <= 1){
			this.$view.find(".pagination_div").remove();
		} else {
			var pagesList = []
			if(this.data.pages_count >= 5){
				for(var i=2; i<=5; i++){

					page_view = $(first_page).clone();
					$(page_view).find("a").text(i);
					if(i == 3){
						$(page_view).find("a").text("...");
					} else if(i == 4){
						$(page_view).find("a").text(this.data.pages_count - 1);
					} else if(i == 5){
						$(page_view).find("a").text(this.data.pages_count);
					}				
					pagesList.push(page_view)

				}

			} else{
				for(var i=2; i <= this.data.pages_count; i++){
					
					page_view = $(first_page).clone();
					$(page_view).find("a").text(i);
					pagesList.push(page_view);
				}				
			}
			var lastPage = first_page;
			for(var i in pagesList){
				$(pagesList[i]).insertAfter($(lastPage))
				lastPage = pagesList[i];
			}
			
			this.$view.find(".pagination li a").click(function(e){
				

				var pageNumber;
				var activePageText = $(this).parents('li').siblings('.pg_active').text();
				if($(this).attr("aria-label") == "Next"){
					pageNumber = parseInt(activePageText) + 1;
					debugger;
					if(parseInt(activePageText) == this_set.data.pages_count){
						return;
					}
					
					if($(this).parents("ul").find("li a").filter(function(){return $(this).text() == ""+pageNumber}).length == 0){
						$(this_set.$view.find(".pagination li a")[1]).html(pageNumber - 1);
						$(this_set.$view.find(".pagination li a")[2]).html(pageNumber);
					}
				}else if($(this).attr("aria-label") == "Previous"){
					debugger;
					if(parseInt(activePageText) == 1){
						return;
					}
					
					pageNumber = parseInt(activePageText) - 1
					if(pageNumber < this_set.data.pages_count - 2){
						$(this_set.$view.find(".pagination li a")[1]).html(pageNumber);
						$(this_set.$view.find(".pagination li a")[2]).html(pageNumber+1);
					}
					
				} else {
					if($(this).text() != "..."){
						activePageText = $(this).text()
						pageNumber = parseInt(activePageText);
					}
				}	

					
				this_set.renderPage(pageNumber);
				
				
				this_set.$view.find(".pagination li").removeClass("pg_active")
				$(this).parents("ul").find("li a").filter(function(){return $(this).text() == ""+pageNumber}).parents('li').addClass("pg_active")
					
			});
			$(this_set.$view.find(".pagination li")[1]).addClass("pg_active");
			
		}

	},
	
	this.renderPage = function(page){
		XPLAIN.AjaxHelper.get("/session/render_page.json?set=" + this.getId() + "&page=" + page, "json", function(data){
			this_set.data.extension = data.set.extension;
			this_set.previousPage = this_set.page;
			this_set.page = page;
			this_set.notify(data.set, "pageChange");
		});
	},
	this.project = function(relation){
		new Project(new Load(this.getId()), relation).execute("json", function(data){
			this_set.data.extension = data.set.extension;
			this_set.notify(data.set);
		});

	},
	this.domain = function(callback){
		XPLAIN.AjaxHelper.get("/session/domain.json?set=" + this.getId(), "json", function(data){
			callback(data);
		});
		
	}
	this.createEmptyView = function(){
		this.$view = $("#setViewTemplate").clone();
		this.$view.find('#windowtitlemin').hide();
		this.$view.attr({
			"id": data.id,
			"exp": "Xset.load('"+data.id+"')",
		});
		

		this.$view.find("#size").html(data.size + " Items");
		this.$view.find("#set_title").html(data.title);
		this.$view.find("#titlemin").html(data.title);
		this.$view.find("#set_title").click(function(e){
			e.stopPropagation();
			this_set.$view.find("#set_title").html("<input type=\"text\" id=\"set_title_input\">");
			this_set.$view.find("#set_title_input").attr("value", this_set.data.title)
			this_set.$view.find("#set_title_input").bind("enterKey",function(e){
				
				this_set.$view.find("#set_title").html($(this).val());
				this_set.$view.find("#titlemin").html($(this).val())
				this_set.setTitle($(this).val());
				
			});
			this_set.$view.find("#set_title_input").focus()
			this_set.$view.find("#set_title_input").keyup(function(e){

			    if(e.keyCode == 13){
			        $(this).trigger("enterKey");
			    }
			});
		});
		
		first_level = this.$view.find(".levels_list").children()[0]
		for(var i=1; i < data.levels; i++){
			level_view = $(first_level).clone()
			level_view.find("label").html("<input type=\"radio\" name=\"filterradio\" class=\"param\" param=\"filter\" param_value=\"equals\" value=\""+(i+1)+"\"> Level" + (i+1));
			this.$view.find(".levels_list").append(level_view);
		}
		
		this.$view.find("#visualize").click(function(e){

			op =  new Flatten(new FindRelations(new Load(this_set.getId())));
			op.execute("json", function(data){
				debugger;
				this_set.$view.find("#properties").empty();
				for(var i in data.set.extension){
					var r = data.set.extension[i];
					if(!r.inverse){
						this_set.$view.find("#properties").append("<li><a class=\"v_property\" tabindex=\"-1\" >"+r.id+"</a></li>");
					}
					
				}
				
				this_set.$view.find(".v_property").click(function(e){
					debugger;
					var relation = this.text
					this_set.project(relation);
		
				});
				
			});
			
		});
		this.$view.find('._show').hide();

		this.init_pagination_list();
		
		if($('#exploration_area').find('.set').length > 0) {
		
			this.$view.insertBefore($('#exploration_area').find('.set').first());
					
		} else {
			this.$view.insertAfter($('#graph_view'));
					
		}
		debugger;

		register_ui_behaviour();


		this.registerProjectBehavior()
		

		// $("#" + this.getId()).tooltip({title: this.getTitle()});

		// $("[data-toggle='tooltip']").tooltip('destroy');
		// $("[data-toggle='tooltip']").tooltip();
		// $("#" + this.getId()).attr('data-original-title', this.getTitle())
		
		

		return this.$view;
	},
	
	this.getItem = function(itemId){
		var result = null;
		for (var i in this.data.extension){
			var item = this.data.extension[i];
			if(item.id == itemId){
				return item;
			} else {
				result = this.deepSearch(item, itemId);
				if(result != null){
					return result;
				}
			}
		}
		return result;
	},
	this.getCurrentPage = function(){
		return this.page;
	},
	this.getPreviousPage = function(){
		return this.previousPage;
	},
    this.deepSearch = function(json, itemId) {
		
        var k1 = Object.keys(json).sort();

        if (k1.length == 0) return null;
		for(var i in k1) {
			if(typeof json[k1[i]] == "object"){
				if(json[k1[i]].id == itemId){
					return json[k1[i]];
				}
				return this.deepSearch(json[k1[i]], itemId)
			}
		}
		return null;
	},
	this.getResultedFrom = function(){
		
		if(this.generatedByOperation){
			var inputSets = []
			this.generatedByOperation.getInputSets(inputSets);
			return inputSets;
		}
		return null;
	},
	this.getItemsArea = function(){
		return this.$view.find("._items_area");
	},
	
	this.getItem = function(itemId){
		return this.itemsHash.get(itemId);	
	},
	this.getId = function(){
		return this.data.id;
	},
	this.getTitle = function(){
		
		return this.data.title;
	},
	this.setTitle = function(title){
		XPLAIN.graph.updateNodeTitle(this.data.id, title);
		this.data.title = title;
		XPLAIN.AjaxHelper.get("/session/update_title?set="+ this.getId()+ "&title=" + title, "json", function(data){});
		$("#" + this.getId()).attr("data-original-title", title);
		return this.data.title;
	},
	this.getExtension = function(){
		return this.data.extension;
	},
	this.isEmpty = function(){
		return (this.data.extension.length == 0)
	},
	XPLAIN.currentSession.addSet(this);
	
	this.getIntention = function(){
		 return this.data.intention
	};
	
}

XPLAIN.Session = function(){
	this.projections = new Hashtable();
	this.sets = new Hashtable();
	this.setIndex = new Hashtable();
	this.index = 1;
	this.addProjection = function(setId, projection){
		if (!this.projections.containsKey(setId)){
			this.projections.put(setId, []);
		}
		this.projections.get(setId).push(projection);
	},
	this.addSet = function(xset){
		this.sets.put(xset.getId(), xset);
		this.setIndex.put(xset.getId(), this.index);
		this.index++;
	},
	this.getSet = function(xsetId){
		if (this.sets.containsKey(xsetId)){
			return this.sets.get(xsetId);
		}
		return null;
		
	},
	this.getSetIndex = function(xset){
		return this.setIndex.get(xset.getId());
	},
	this.getProjections = function(setId){
		if(this.projections.containsKey(setId)){
			return this.projections.get(setId);
		}
		return [];
		
	},
	this.allProjections = function(){
		var projections = [];
		for(var i in this.projections.values()){
			var setProjections = this.projections.values()[i];
			for(var j in setProjections){
				projections.push(setProjections[j]);
			}
		}
		return projections;
	}
}

XPLAIN.currentSession = XPLAIN.currentSession || new XPLAIN.Session();

