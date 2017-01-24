class SessionController < ApplicationController
  
    
  def index
    s = Xset.new do |s|
      s.server = SERVER
      s.id = "original"
    end
    s.save
    @sets = [s]
  end
  
  def execute
    puts "EXPRESSION: " << params[:exp]
    
    @resourceset = eval(params[:exp])
   
    @resourceset.save
    if(params[:exp].include?("group"))
      @render_relations = true;
    end
    respond_to do |format|
      format.js
    end    
  end
  
  
  def nextpage
    @resourceset = Xset.load(params[:set])
    page_to_display = params[:page].to_i
    
    @resourceset.paginate(page_to_display, 5)
    respond_to do |format|
      format.js
    end
  end
  
  def renderdomain
    @resourceset = Xset.load(params[:set])
    respond_to do |format|
      format.js
    end
    
  end
  
  def all_relations
    server = Xset.load('default').server
    @resourceset = Xset.new do |s|
      server.relations.each do |relation|
        s << relation
      end
      s.server = server
    end

    @render_relations = false;  
    respond_to do |format|
      if @resourceset.save
        format.js { render :file => "/session/execute.js.erb" }
      end
    end 
  end
  
  def all_types
    server = Xset.load('default').server
    @resourceset = Xset.new do |s|
      server.types.each do |relation|
        s << relation
      end
      s.server = server
    end
 
    @render_relations = false;  
    
    respond_to do |format|
      if @resourceset.save
        format.js { render :file => "/session/execute.js.erb" }
      end
    end 
  end
  
  def search
    server = Xset.load('default').server
    keywords = params[:keywords]
    @resourceset = Xset.new do |s|
      server.search(keywords).each do |item|      
        s << item     
      end
      s.server = server
    end
    @render_relations = false;
    respond_to do |format|
      if @resourceset.save
        format.js { render :file => "/session/execute.js.erb" }
      end
    end     
  end
  
  def item_relations
  end
  
  def relations
    server = Xset.load('default').server
    query = server.begin_nav_query do |q|        
      q.on(Entity.new(params[:id]))
      q.find_relations
    end    
    results_hash = query.execute
    @relations = results_hash.values    
    respond_to do |format|
      format.js
    end     
  end
  
  def common_relations

    set = Xset.load(params[:set])
    newset = Xset.new do |s|     
      s << Relation.new("http://wwww.w3.org/2000/01/rdf-schema#label")
      s.server = set.server
    end
    
    @common_relations = newset
    respond_to do |format|
      format.js
    end
  end
  
  def instances
    server = Xset.load('default').server
    type = Type.new(params[:type])
    type.add_server(server)
    puts "FINDING INSTANCES FOR: #{type.to_s}"
    puts "  #{type.instances.size}"
    @resourceset = Xset.new do |s|      
      type.instances.each do |item|
        s << item
      end
      s.server = server
    end

    @render_relations = false;  
    
    respond_to do |format|
      if @resourceset.save
        format.js { render :file => "/session/execute.js.erb" }
      end
    end    
  end
  
  def select
    selected_items = params[:selected];
    @resourceset = Xset.new do |s|
      selected_items.each do |item|
        s << Entity.new(item)
      end
      s.server = Xset.load('default').server
    end
    respond_to do |format|
      if @resourceset.save
        format.js { render :file => "/session/execute.js.erb" }
      end
    end    
  end
  
  def project
    set = Xset.load(params[:set])
    @projection_set = set.pivot_forward([params[:relation]])
    @projected_set = @projection_set.resulted_from
    @projection_relation = params[:relation]
    respond_to do |format|
      format.js
    end    
  end
  
  def new
  end
end
