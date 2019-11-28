require 'timeout'
class SessionController < ApplicationController
  protect_from_forgery except: :new
  before_filter :load_temp_session
  
  def load_temp_session
    if !session[:current_session]
      session[:current_session] = Xplain::Session.create(title: "Unnamed").id
    end
  end
    
  def load_last_active_session
    current_session = Xplain::Session.load(session[:current_session])
    
    respond_to do |format|
      
      format.json {render :json =>  render_session_json(current_session)}
    end
  end
  
  def render_template(template_path, context={}, set = nil)
    #TODO change to get the template from a resourceset attribute
    #TODO not actually rendering partial within the template
    view = ActionView::Base.new(ActionController::Base.view_paths, {:set => set})
    
    template_html = view.render({:file => template_path})
    template_html
  end
    
  def index
  end
  
  def apply_facet
    current_session = Xplain::Session.load(session[:current_session])
    set = Xplain::ResultSet.load(params[:id])

    begin
    filtered_set = current_session.execute(eval("set.refine(visual: true){#{params[:filter]}}"))
      
    relations_set = current_session.execute(filtered_set.pivot(visual: true){relation "relations"}) 
    Xplain::Visualization.current_profile.set_view_properties(relations_set.nodes)
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

    respond_to do |format|
      format.json {render :json => generate_jbuilder(relations_set, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}
    end
  end

  def export
    triples = ""
    current_session = Xplain::Session.load(session[:current_session])
    result_set = Xplain::ResultSet.load(params[:id])
    relations_set = current_session.execute(result_set.pivot{relation "relations"})    
    relations_map = []
    relations_set.nodes.map do |item_rel| 
      if !item_rel.item.inverse?
        pivoted_set = current_session.execute(result_set.pivot(group_by_domain: true){relation item_rel.item})
        relations_map << [item_rel.item, pivoted_set]
      end
    end

    relations_map.each do |r_map|
      
      predicate = "<#{Xplain::Namespace.expand_uri(r_map[0].id)}>"
      r_map[1].nodes.each do |node|
        subject = "<#{Xplain::Namespace.expand_uri(node.item.id)}>"

        node.children.each do |cnode|
          if cnode.item.is_a? Xplain::Literal
            object = "\"#{cnode.item.text.gsub('"', '\"')}\"^^<#{cnode.item.datatype}>"
          else
            object = "<#{Xplain::Namespace.expand_uri(cnode.item.id)}>"
          end
          triples << "#{subject} #{predicate} #{object}.\n"
        end
      end      
    end
    #File.open("rdf_export.txt", 'a'){|f| f.write(triples)}
    respond_to do |format|
      format.any {render :text => triples}
    end
  end

  def render_faceted_search

    current_session = Xplain::Session.load(session[:current_session])
    set = Xplain::ResultSet.load(params[:id])
    
    if params[:relation]
      inverse = false
      if params[:inverse]
        inverse = eval(params[:inverse])
      end
      begin
        relation = Xplain::SchemaRelation.new(id: params[:relation], inverse: inverse)
        grouped_set =  current_session.execute(set.group(visual: true){by_image relation})
        
        mapped_set = current_session.execute(grouped_set.aggregate(visual: true){count})
        
        facets = []
        
        ranked_set = current_session.execute(mapped_set.rank(visual: true, order: :desc, level: 2){by_level{}})
        facets_json = {
          source_set: set.id,
          facet_group: to_json(relation),
          facets: ranked_set.nodes.map{|fnode| to_json(fnode.item).merge({size: fnode.children[0].item.value})} 
        }
      rescue Exception=>e
        puts e.message
        puts e.backtrace
      end
      
      respond_to do |format|
        format.json{render json: facets_json}
      end
    end
  end

=begin  def render_faceted_search

    current_session = Xplain::Session.load(session[:current_session])
    set = Xplain::ResultSet.load(params[:id])
    
    
    
    grouped_sets = []
    if params[:relation]
      inverse = false
      if params[:inverse]
        inverse = eval(params[:inverse])
      end
      
      relation = Xplain::SchemaRelation.new(id: params[:relation], inverse: inverse)
      grouped_sets << current_session.execute(set.group{by_image relation})
    else
      pivot_rs = current_session.execute(set.pivot{relation "relations"})
      grouped_sets = pivot_rs.nodes.map{|item_rel| current_session.execute(set.group{by_image item_rel.item})}
    end

    if params[:filter]
      grouped_sets = grouped_sets.map do |gset|
        current_session.execute(eval("gset.refine{#{params[:filter]}}"))
      end
    end
    mapped_sets = []
    grouped_sets.each{|gset| mapped_sets << current_session.execute(gset.aggregate{count})}
    
    facets = []
    for i in (0..mapped_sets.size-1) do
      mapped_set = mapped_sets[i]
      ranked_set = current_session.execute(mapped_set.rank(order: :desc, level: 2){by_level{}})
      if !params[:relation]
        relation = pivot_rs.nodes[i].item
      end
      
      facets << [relation, ranked_set]
    end
    
    facets_json = facets.map do |facet|
        {
          source_set: set.id,
          facet_group: to_json(facet[0]),
          facets: facet[1].nodes.map{|fnode| to_json(fnode.item).merge({size: fnode.children[0].item.value})} 
        }
    end

    respond_to do |format|
      format.json{render json: facets_json}
    end

  end
=end
  def to_json(item)
    item_json = {
      text: item.text,
      type: item.class.name,
    }
    if !item.is_a? Xplain::Literal
      item_json[:id] = item.id
    else
      item_json[:id] = item.text,
      item_json[:datatype] = item.datatype
    end
    item_json

  end

  def render_operation
    
    respond_to do |format|
      if params[:operation]
        format.json{ render json: render_template('operations/_' + params[:operation].to_s + '.html.erb')}
      else
        format.json{ render status: "You must provide the operation ID!"}
      end
    end
    
    
    operation_name = params[:operation]
    
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
  
  def render_view
    view = params[:view].downcase
    @items_set = Xplain::ResultSet.load(params[:set])
    
    json = Jbuilder.new do |viewJson|
      viewJson.html render_template(view+ '/_'+view+ '.html.erb')
    end.target!

    respond_to do |format|
      format.js
      format.json {render :json => json}
    end
    
  end
  
  
  def execute
    
    start = Time.now
    should_paginate = params[:should_paginate] != "false"
    begin
      expression = params[:exp].gsub("%23", "#")
      current_session = Xplain::Session.load(session[:current_session])
      
      eval_results = eval(expression)
      if !eval_results.is_a? Xplain::ResultSet
        if current_session
          @resourceset = current_session.execute(eval_results)
        else
          @resourceset = eval_results.execute()
        end
      else
        @resourceset = eval_results
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
    Xplain::Visualization.current_profile.set_view_properties(@resourceset.nodes)
    
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(@resourceset, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb'), 'DefaultSetWidget', 1, should_paginate).target!}
      format.any {render :text => "SUCCESSFUL"}
      finish = Time.now 
      puts "CONTROLLER EXECUTED: #{(finish - start).to_s}"
    end
  end
 
   def set_endpoint

    params[:read_timeout] = 3000
    params[:method] = 'post' if (params[:method] != 'get' && params[:method] != 'post')
    current_session = Xplain::Session.load(session[:current_session])
    

    respond_to do |format|
      begin

        current_session.set_server params
        current_session.save
        format.any {render :text => "SUCCESSFUL"}
      rescue RepositoryConnectionError => e
        format.json{render json: { error:  [e.message]}}
      end    
    end
  end
  
  def namespace
      
    if params[:namespace_list]
      Xplain::Namespace.update(params[:namespace_list])
    end
    
    respond_to do |format|
      format.json {render :json => generate_namespace_json()}
    end
  end
  
  def generate_namespace_json
    Jbuilder.new do |json|
      json.array!(Xplain::Namespace.each) do |namespace|
        json.uri namespace.uri
        json.prefix namespace.prefix
      end
    end.target!
  end
  
  def execute_update()
    update_expression = params[:update].gsub("%23", "#")
    
    respond_to do |format|
      format.any {render :text => eval(update_expression).to_s}
    end
  end
  
  def render_page
    
    
    resourceset = Xplain::ResultSet.load(params[:set])
    
    items_page = params[:page].to_i
    items_page = 1 if(items_page == 0)
    default_template_file = (Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(resourceset, render_template(default_template_file), nil, items_page).target!}
      format.any {render :text => "SUCCESSFUL"}
    end    
  end
  
  def list_sessions
    @section_list = Xplain::Session.list_titles
    @section_list.delete("Unnamed")
    @section_list.delete(Xplain::Session.load(session[:current_session]).title)
    view = ActionView::Base.new(ActionController::Base.view_paths, {section_list: @section_list})
    template_html = view.render({partial: "session/section_list"})
    
    respond_to do |format|
      format.json{render :json => Jbuilder.new{|set_json| set_json.html template_html}.target!}
    end
  end
  
  def execute_visual
    begin
      expression = params[:exp].gsub("%23", "#")
      result_set = eval(expression)
      
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
    
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(result_set, "").target!}
      format.any {render :text => "SUCCESSFUL"}
    end
  end
  
  def delete_set
    current_session = Xplain::Session.load(session[:current_session])
    set_to_delete = Xplain::ResultSet.load(params[:id])
    begin
      current_session.remove_result_set_permanently(set_to_delete)
    rescue Exception => e
      puts e.message
      puts e.backtrace        

    end
    respond_to do |format|
      format.json{render :json => Jbuilder.new(){|json| json.removed_set params[:id]}.target!}
    end
  end
  
  def calculate_extension
    resourceset = Xplain::ResultSet.load(params[:set])
    resourceset.fetch()
    items_page = 1
    default_template_file = (Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(resourceset, render_template(default_template_file), nil, items_page).target!}
      format.any {render :text => "SUCCESSFUL"}
    end
  end
  
  def save_session
    name = params[:name].to_s
    current_session = Xplain::Session.load(session[:current_session])
    if !name.empty? && name != current_session.title
      puts "FROM: #{current_session.title} TO: #{name}"
      begin
        new_session = current_session.deep_copy
        new_session.title = name
      rescue Exception => e
        puts e.message
        puts e.backtrace        
      end

      if current_session.title == "Unnamed"
        current_session.delete
      end
      begin
        new_session.save
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
      session[:current_session] = new_session.id
    else
      begin
        current_session.save
      rescue Exception => e
        puts e.message
        puts e.backtrace
      end
    end
    
    respond_to do |format|
      format.json{render :json => Jbuilder.new(){|json| json.message "Success"}.target!}
    end 
  end

  def save_path
    respond_to do |format|
      begin
        path_expr = params[:expr]
        eval(path_expr).save
        current_session = Xplain::Session.load(session[:current_session])
        current_session.clear_cache_by_intention_slice("relation \"relations\"")
        format.js{render :inline=>"alert(\"Relation path has been saved!\")"}
      rescue Exception => e
        puts e.message
        puts e.backtrace
        format.js {render :inline=>"alert(\"Error! Relation path has not been saved.\")"}
      end
    end
  end

  def endpoint
    server_list = Xplain::Session.load(session[:current_session]).server.class.load_all()
    response_json = Jbuilder.new do |json|
      json.array!(server_list) do |server|
        #TODO implement accessors for these attrs.
        json.url server.params[:graph]
        json.named_graph server.params[:named_graph]
        json.is_blz_graph server.class == BlazegraphDataServer
      end
    end.target!
    respond_to do |format|
      format.json{render :json => response_json}
    end
  end
  
  def all_types
    ruby_expression = "Xplain::SchemaRelation.new(id: \"has_type\", server: @server).image"
    current_session = Xplain::Session.load(session[:current_session])
    server = nil
    if current_session
      server = current_session.server
    end

    @result_set = Xplain::ExecuteRuby.new(code: ruby_expression)
    Xplain::Visualization.current_profile.set_view_properties(@result_set.nodes)
    respond_to do |format|

      format.js { render :file => "/session/execute.js.erb" }
      format.json {render :json => generate_jbuilder(@result_set, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}

    end 
  end
  
  def load_all_resultsets
    begin
      all_result_sets_ordered = Xplain::Session.load(session[:current_session]).each_result_set_tsorted(exploration_only: true)
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
    result_sets_json = "[#{all_result_sets_ordered.map{|rs| generate_jbuilder(rs, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}.join(", ")}]"
    respond_to do |format|
      format.json {render :json =>  result_sets_json}
    end
  end
  
  def load_session
    
    if params[:id]
      session_found = Xplain::Session.load(params[:id])
    elsif params[:name]
      session_id = params[:name]
      session_found = Xplain::Session.find_by_title(session_id).first
    end
    
    

    respond_to do |format|
      if session_found
        session[:current_session] = session_found.id
        format.json {render :json =>  render_session_json(session_found)}
      else
        format.json {render :json =>  "errorMessage: \"Session #{params[:name]} does not exist!\""}
      end
    end

  end
  
  def render_session_json(exp_session)
    begin
      
      result_sets_json = "{\"server\": \"#{exp_session.server.url}\", \"name\":\"#{exp_session.title}\",\"sets\":[#{exp_session.each_result_set_tsorted(exploration_only: true).map{|rs| generate_jbuilder(rs, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb', {}, rs)).target!}.join(", ")}]}"
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end

  end
  
  def search
    current_session = Xplain::Session.load(session[:current_session])
    input = Xplain::ResultSet.load(params[:set])
    search_operation = Xplain::KeywordSearch.new(inputs: input.intention, keyword_phrase:  params[:str].to_s, inplace: true, visual: true)
    
    rs = current_session.execute(search_operation)
    Xplain::Visualization.current_profile.set_view_properties(rs.nodes)
    respond_to do |format|

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(rs, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}
      
    end
  end

    
  def new
    current_session = Xplain::Session.load(session[:current_session])
    respond_to do |format|
      format.js
    end
  end
  
  def create
    current_session = Xplain::Session.load(session[:current_session])
    server = Xplain.default_server 
    if current_session
      server = current_session.server
    end
    new_session = Xplain::Session.create(title: params[:name])
    new_session.server = server
    new_session.save
    session[:current_session] = new_session.id
    respond_to do |format|
      format.json {render :json => "{\"message\":\"session #{params[:name]} saved\"}"}
    end
  end
  
  def close
    if session[:current_session]
      current_session = Xplain::Session.load(session[:current_session])
      if current_session && current_session.title != "Unnamed"
        current_session.save
      end
    end
    Xplain::memory_cache.clear
    session[:current_session] = Xplain::Session.create(title: "Unnamed").id
    respond_to do |format|
      format.any {render :json => "{\"message\":\"session closed\"}"}
    end
  end
  
  def generate_jbuilder(result_set, template_html, component_name = 'DefaultSetWidget', page = 1, should_paginate=true)
    if should_paginate
      total_by_page = 20
    else
      total_by_page = result_set.size
    end
    puts "TOTAL BY PAGE: #{total_by_page}"
    json = Jbuilder.new do |set_json|
      set_json.id result_set.id
      set_json.title result_set.title
      set_json.view template_html
      set_json.itemsView 'JstreeListView'
      set_json.pages_count result_set.count_pages(total_by_page)
      set_json.size result_set.size
      if result_set.intention && result_set.intention.is_a?(Xplain::Operation)
        set_json.intention_label result_set.intention.summarize
      end
      set_json.componentName component_name
      set_json.resultedFrom Jbuilder.new do |input_json| 
        input_json.array!(result_set.resulted_from){|input| input_json.id input.id}
      end
      set_json.history Jbuilder.new do |input_json| 
        input_json.array!(result_set.history){|input| input_json.id input.id}
      end

      set_json.view_options ['Accordion', 'Grid']
      set_json.extension Jbuilder.new do |ext_json|
        ext_json.array!(result_set.get_page(total_by_page, page)) do |node|
          to_jbuilder(node, ext_json, result_set)
          
        end
      end
    end
    json
  end
  
  
  def to_jbuilder(node, jbuilder_obj, set)
    if node.item.is_a? Xplain::Literal
      jbuilder_obj.id node.item.value
      jbuilder_obj.text node.item.value
      
      if node.item.datatype
        jbuilder_obj.datatype node.item.datatype
      end
    else
      jbuilder_obj.id node.item.id
      jbuilder_obj.text node.item.text
    end
    jbuilder_obj.node node.id
    jbuilder_obj.set set.id
    jbuilder_obj.type node.item.class.to_s
    jbuilder_obj.inverse node.item.inverse?.to_s if node.item.respond_to? :inverse?
    jbuilder_obj.intention node.item.intention if node.item.respond_to? :intention
    jbuilder_obj.children Jbuilder.new do |children_json|
      children_json.array!(node.children) do |child_node|
        to_jbuilder(child_node, children_json, set)      
      end      
    end
  end
end
