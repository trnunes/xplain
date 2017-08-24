require 'timeout'
class SessionController < ApplicationController
  before_action :load_current_session
  
  def load_current_session
    # binding.pry
    # reset_session
    # session[:current_session] = nil
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
  
  def help
    @operation = params[:operation]
    @div_id = params[:div]
    if(@operation)
      @div_id ||= @operation + "_help"
    end

    
    respond_to do |format|
      format.js do 
        if @operation
          render :action => 'operation_help'
        else
          render :action => 'help'
        end
        
      end
    end   
    
  end
  
  def execute

    @group_page = params[:page].to_i
    @group_page = 1 if(@group_page == 0)
    @items_page = params[:page].to_i
    @items_page = 1 if(@items_page == 0) 
    
    start = Time.now
    begin
      # begin
      #   status = Timeout::timeout(10) {@resourceset = eval(params[:exp])}
      # rescue Timeout::Error
      #   render {:json=>'This is taking way too long.'}
      # end
      @resourceset = eval(params[:exp])
      if(@resourceset.intention.class != Explorable::Rank)
        @resourceset.natural_sort!
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
      Filtering.clear()
    end
    # binding.pry
    #Xpair::Session.load(session[:current_session]).save_expression(params[:exp])
    # binding.pry
    @resourceset.index.paginate(20)
    
    @resourceset.save
    # binding.pry
    
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
    
    @items_page = params[:page].to_i
    @items_page = 1 if(@items_page == 0)
    @group_page = @items_page
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
      server = Xset.load('default_set').server
      @resourceset = Xset.new("all_relations", "relations") 

      server.relations.each do |relation|
        @resourceset.add_item relation
      end
      @resourceset.server = server

      @resourceset.index.paginate(20)
      @resourceset.id = "all_relations"
      
    end
    # binding.pry
    @resourceset.title = "All Relations"
    #Xpair::Session.load(session[:current_session]).save_expression("Xset.load('root').find_relations()")
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
    @items_page = 1
    @group_page = 1
    
    if(@resourceset.nil?)
      server = Xset.load('default_set').server
      
      @resourceset = Xset.new("all_types", "types")
      server.types.each do |item|
        @resourceset.add_item item
      end
      @resourceset.server = server

      @resourceset.index.paginate(20)
      @resourceset.id = "all_types"
      
    end
    #Xpair::Session.load(session[:current_session]).save_expression("Xset.load('root').pivot(SchemaRelation.new(\"rdf:type\"))")
    @resourceset.title = "Types"
    respond_to do |format|
      if @resourceset.save

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(@resourceset)}
      end
    end     
  end
  
  def refine
    input = Xset.load(params[:set])
    @resourceset = input.v_refine{|gf| gf.keyword_match(keywords: [params[:str]])}
    respond_to do |format|
      if @resourceset.save

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(@resourceset)}
      end
    end     
    
    
  end
  
  def search
    @items_page = 1
    @group_page = 1
    server = Xset.load('default_set').server
    keywords = params[:keywords]
    @resourceset = Xset.new(SecureRandom.uuid, "search(\"#{keywords.inspect}\")")
    # server.search(keywords).each do |item|
    server.blaze_graph_search(keywords).each do |item|
      @resourceset.add_item item     
    end
    @resourceset.server = server
    @resourceset.index.paginate(20)
    Explorable.exploration_session.add_set @resourceset
    @resourceset.natural_sort!
    # binding.pry
    #Xpair::Session.load(session[:current_session]).save_expression("Xset.load('root').refine{|f| f.keyword_match(\"#{keywords.inspect}\")}")
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
    server = Xset.load('default_set').server
    type = Type.new(params[:type])
    type.add_server(server)
    @items_page = 1
    @group_page = 1
    
    @resourceset = Xset.new('instances', "pivot(select(type), \"typeOf\")")

    @resourceset.resulted_from = Xset.load(params[:set])

    type.instances.each{|t| @resourceset.add_item t}
    @resourceset.server = server

    @resourceset = @resourceset.select_items([type]).pivot(relations: [SchemaRelation.new(Xpair::Namespace.expand_uri("rdf:type"), true)])
    Explorable.exploration_session.add_set @resourceset
    # binding.pry
    @resourceset.index.paginate(20)
    # binding.pry
    @page = 1
    #Xpair::Session.load(session[:current_session]).save_expression("Xset.load('#{@resourceset.id}').select_items([Type.new(\"#{params[:type]}\")]).pivot(relations: [SchemaRelation.new(\"rdf:type\"), true)])")
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
  
  def domain
    set = Xset.load(params[:set])
    target_json = Jbuilder.new do |json|
      json.array!(set.each_domain) do |domain_item|
        to_jbuilder(json, domain_item, set)
      end
    end.target!
    respond_to do |format|
      format.json {render :json => target_json}
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
    @parents_by_item
    json = Jbuilder.new do |set|
      set.set do
      	set.id xset.id
        set.title xset.title
        set.pages_count xset.index.count_pages
      	set.resultedFrom xset.resulted_from.id if !xset.resulted_from.nil?  
      	set.intention xset.v_expression
      	set.size xset.each_item.size
      	set.extension build_subtree(xset.index, Jbuilder.new, xset)
      end
    end
    # binding.pry

    json.target!
  end
  
  def parse_indexed_items(json, entry, xset)
    items = entry.indexed_items(@items_page)
    # binding.pry
    if(xset.intention.class != Explorable::Rank)
      items = items.sort{|i1, i2| i1.text <=> i2.text}
    end
    # binding.pry
    json.array!(items) do |item|
      to_jbuilder(json, item, xset)
    end
  end
  
  def parse_children(json, entry, xset)
    items = entry.children(@group_page)
    # binding.pry
    if(xset.intention.class != Explorable::Rank)
      items = items.sort{|i1, i2| i1.to_s <=> i2.to_s}
    end
    json.array!(items) do |child|
      build_subtree(child, json, xset)
    end
  end
  
  def build_subtree(parent, json, xset)


    to_jbuilder(json, parent.indexing_item, xset)  unless(parent.indexing_item == 'root')
    # binding.pry
    if(parent.children(@group_page).empty?)
      if(parent.indexing_item == 'root')
        parse_indexed_items(json, parent, xset)
      else
        json.children Jbuilder.new do |child_json|
          parse_indexed_items(child_json, parent, xset)
        end
      end
      # binding.pry
    else
      
      if(parent.indexing_item == 'root')
        parse_children(json, parent, xset)
      else
        json.children Jbuilder.new do |child_json|
          parse_children(child_json, parent, xset)
        end
      end
      # binding.pry

    end
    json
  end
  
  # def build_extension(images, xset, subset="")
  #   extension = []
  #
  #   # binding.pry
  #   Jbuilder.new do |json|
  #
  #     json.array!(images) do |item|
  #
  #       # binding.pry
  #       if(item.is_a? Xsubset)
  #         # binding.pry
  #         to_jbuilder(json, item.key, xset, item.id)
  #         # binding.pry
  #         json.children Jbuilder.new do |image_json|
  #           image_json.array!(item.keys) do |key|
  #             relations = item[key]
  #             to_jbuilder(image_json, key, xset, item.id)
  #             if(relations.is_a? Xsubset)
  #               json.children build_extension(relations.extension, xset, relations.id)
  #             else
  #               json.children Jbuilder.new do |relations_json|
  #                 relations_json.array!(relations) do |relation|
  #                   to_jbuilder(relations_json, relation, xset, item.id)
  #                 end
  #               end
  #             end
  #           end
  #         end
  #         # binding.pry
  #       else
  #         to_jbuilder(json, item, xset, subset)
  #       end
  #
  #     end
  #   end
  # end
  
  def to_jbuilder(json, item, xset, subset_id= "")
  	if(item.is_a?(Entity) || item.is_a?(SchemaRelation)|| item.is_a?(ComputedRelation) || item.is_a?(Type))

	  	json.id item.id
      # binding.pry
      if item.text.nil?
        json.text item.id
      else
        json.text item.text
      end
			
			json.type item.class.to_s
			json.inverse item.inverse if item.is_a?(SchemaRelation)	
		else
			json.id item.to_s
      # binding.pry
			json.text item.text
			json.type "Xpair::Literal"
      if item.has_datatype?
        json.datatype item.datatype
      end
		end
    json.expression item.expression

    if !subset_id.empty?
      json.subset subset_id
    end

    json.parents Jbuilder.new do |cjson|
      cjson.array!(item.parents) do |child|
        to_jbuilder(cjson, child, xset)
      end
    end
    
  	json.set xset.id
    if !xset.resulted_from.nil?
      resulted_from_array = []
      resulted_from_set = xset.resulted_from
      
      while(!resulted_from_set.nil?)
        resulted_from_array.unshift(resulted_from_set.id)
        resulted_from_set = resulted_from_set.resulted_from
      end
      
    	json.resultedFrom xset.resulted_from.id
      json.resultedFromArray Jbuilder.new do |resulted_from_json|
        resulted_from_json.array!(resulted_from_array) do |resulted_from|
          resulted_from_json.id resulted_from
        end
      end
    end
  end

end
