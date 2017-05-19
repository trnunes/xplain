class SessionController < ApplicationController
  before_action :load_current_session
  
  def load_current_session
    # binding.pry
    # reset_session
    session[:current_session] = nil
    if(session[:current_session].nil?)
      exp_session = Xpair::Session.new
      exp_session.save
      session[:current_session] = exp_session.id
    end
      
    
    @session = Xpair::Session.load(session[:current_session])
  end
    
  def index
    s = Xset.new do |s|
      s.server = SERVER
      s.id = "original"
    end
    s.save
    @sets = [s]


  end
  
  def execute

    @page = 1
    start = Time.now
    begin
      @resourceset = eval(params[:exp])
    rescue Exception => e
      puts e.backtrace
    end
    if params[:render_relations].nil?
      @render_relations = false
    else
      @render_relations = eval(params[:render_relations])
    end    
    # binding.pry
    @resourceset.paginate(20)
    @resourceset.save
    @session.add_set(@resourceset)

    if(params[:exp].include?("group"))
      @render_relations = true;
    end
    
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(@resourceset)}
      format.any {render :text => "SUCCESSFUL"}
      finish = Time.now 
      puts "CONTROLLER EXECUTED: #{(finish - start).to_s}"
    end   

  end
  
  
  def render_page
    @resourceset = Xset.load(params[:set])
    @page = params[:page].to_i

    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(@resourceset)}
      format.any {render :text => "SUCCESSFUL"}
    end    
  end
  
  def renderdomain
    @resourceset = Xset.load(params[:set])
    respond_to do |format|
      format.js
    end
    
  end
  
  
  def update_title
    @resourceset = Xset.load(params[:set])
    @resourceset.title = Xset.load(params[:title])
    @resourceset.save
    respond_to do |format|
      format.any {render :text => "SUCCESSFUL"}
    end    
    
  end
  
  def all_relations
    @page = 1
    @resourceset = Xset.load("all_relations")

    if(@resourceset.nil?)
      server = Xset.load('default').server
      @resourceset = Xset.new do |s|
        server.relations.each do |relation|
          s << relation
        end
        s.server = server
      end
      @resourceset.paginate(20)
      @resourceset.id = "all_relations"
      @session.add_set(@resourceset)
    end
    # binding.pry
    @resourceset.title = "All Relations"
    respond_to do |format|
      if @resourceset.save
        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(@resourceset)}
      end
    end 
  end
  
  def all_types
    @page = 1
    @resourceset = Xset.load("all_types")
    
    if(@resourceset.nil?)
      server = Xset.load('default').server
      @resourceset = Xset.new do |s|
        server.types.each do |relation|
          s << relation
        end
        s.server = server
      end
      @resourceset.paginate(20)
      @resourceset.id = "all_types"
      @session.add_set(@resourceset)
    end
    @resourceset.title = "Types"
    respond_to do |format|
      if @resourceset.save

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(@resourceset)}
      end
    end     
  end
  
  def search
    server = Xset.load('default').server
    keywords = params[:keywords]
    @resourceset = Xset.new do |s|
      # server.search(keywords).each do |item|
      server.blaze_graph_search(keywords).each do |item|
        s << item     
      end
      s.server = server
    end
    @resourceset.paginate(20)
    @page = 1
    @session.add_set(@resourceset)
    respond_to do |format|
      if @resourceset.save

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(@resourceset)}
      end
    end     
  end
  
  def item_relations
  end
  
  def relations
    input_set = Xset.load(params[:set])
    selection_set = input_set.select([Entity.new(params[:id])])
    selection_set.each do |item|

    end
    @resourceset = selection_set.pivot
    
    @resourceset.save
    @session.add_set(@resourceset)
    respond_to do |format|
      format.js
    end     
  end
  
  def common_relations

    set = Xset.load(params[:set])
    
    @common_relations = set.relations()
    respond_to do |format|
      format.js

    end
  end
  
  def instances
    start = Time.now
    server = Xset.load('default').server
    type = Type.new(params[:type])
    type.add_server(server)
    
    @resourceset = Xset.new do |s|      
      s.extension = type.instances.map{|i| [i, {}]}.to_h
      s.server = server
    end

    # binding.pry
    @resourceset.paginate(20)
    # binding.pry
    @page = 1
    @session.add_set(@resourceset)
    finish = Time.now

    puts "CONTROLLER EXECUTED: #{(finish - start).to_s}"     
    # binding.pry
    
    respond_to do |format|
      if @resourceset.save

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(@resourceset)}
        # binding.pry
      end
    end
  end
  
  def select
    selection_set = params[:set]
    selected_items = params[:selected];
    selected_items.each{}
    @resourceset = selection_set.select(selected_items.map{})
    @session.add_set(@resourceset)
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
  
  def trace_subset_domains
    set = Xset.load(params[:set])
    subset = set.get_subset(params[:subset])


    domains = set.trace_domains(subset)
    # binding.pry

    target_json = Jbuilder.new do |json|
      json.array!(domains) do |local_domains|
        json.id local_domains.first
        json.domains Jbuilder.new do |domain_json|
          domain_json.array!(local_domains[1..local_domains.size]) do |local_domain|
            domain_json.id local_domain.id
            domain_json.type local_domain.class.to_s
          end
        end
      end
    end.target!
        
    respond_to do |format|
      format.json {render :json => target_json}
    end     
    
  end
  
  def trace_item_domains
    set = Xset.load(params[:set])
    item = set.get_item(params[:item].gsub(" ", "%20"))
    # binding.pry
    domains = set.trace_domains(item)

    # binding.pry
    target_json = Jbuilder.new do |json|
      json.array!(domains) do |local_domains|
        json.id local_domains.first
        json.domains Jbuilder.new do |domain_json|
          domain_json.array!(local_domains[1..local_domains.size]) do |local_domain|
            if local_domain.is_a? Xpair::Literal
              domain_json.id local_domain.value
            else
              domain_json.id local_domain.id
            end
            
            domain_json.type local_domain.class.to_s
          end
        end
      end
    end.target!
        
    respond_to do |format|
      format.json {render :json => target_json}
    end     
    
  end
  
  def get_level
    set = Xset.load(params[:set])
    level_items = set.select_level(params[:level].to_i).map{|items_hash| items_hash.keys}.flatten
    respond_to do |format|
      format.json {render :json => build_json(level_items, set)}
    end
    
  end
  
  def new
  end
  
  def build_json(items, set)
    Jbuilder.new do |json|
      json.array!(items) do |item|
        to_jbuilder(json, item, set)
      end
    end.target!
  end
  
  def generate_jbuilder(xset)
    # binding.pry
    json = Jbuilder.new do |set|
      set.set do
      	set.id xset.id
        set.title xset.title
        set.pages_count xset.count_pages
      	set.resultedFrom xset.resulted_from.id if !xset.resulted_from.nil?  
      	set.intention xset.expression
      	set.size xset.size
        set.levels xset.count_levels
        set.generates = Jbuilder.new do |generated_set_json|
          generated_set_json.array!(xset.generates) do |generated_set|
            generated_set_json.id = generated_set.id
          end
        end
      	set.extension build_extension(xset.each_image(page: @page), xset)
      end
    end
    json.target!
  end
  
  def build_extension(images, xset, subset="")
    extension = []    
      
    # binding.pry
    Jbuilder.new do |json|

      json.array!(images) do |item|

        # binding.pry
        if(item.is_a? Xsubset)
          # binding.pry
          to_jbuilder(json, item.key, xset, item.id)
          # binding.pry
          json.children Jbuilder.new do |image_json|            
            image_json.array!(item.keys) do |key|
              relations = item[key]
        	  	to_jbuilder(image_json, key, xset, item.id)
              if(relations.is_a? Xsubset)
                json.children build_extension(relations.extension, xset, relations.id)
              else
                json.children Jbuilder.new do |relations_json|
                  relations_json.array!(relations) do |relation|
                    to_jbuilder(relations_json, relation, xset, item.id)
                  end
                end
              end            
            end            
          end
          # binding.pry
        else
          to_jbuilder(json, item, xset, subset)
        end
        
      end
    end
  end
  
  def to_jbuilder(json, item, xset, subset_id= "")
  	if(item.is_a?(Entity) || item.is_a?(Relation)|| item.is_a?(Type))

	  	json.id item.id
      if item.text.nil?
        json.text item.id
      else
        json.text item.text
      end
			
			json.type item.class.to_s
			json.inverse item.inverse if item.is_a?(Relation)	
		else
			json.id item.to_s
      # binding.pry
			json.text item.text
			json.type "Xpair::Literal"
      if item.has_datatype?
        json.datatype item.datatype
      end
		end


    if !subset_id.empty?
      json.subset subset_id
    end

    json.parents Jbuilder.new do |cjson|
      cjson.array!(item.parents) do |child|
        to_jbuilder(cjson, child, xset)
      end
    end
    
  	json.set xset.id
  	json.resultedFrom xset.resulted_from.id if !xset.resulted_from.nil?
  end

end
