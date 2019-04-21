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
    
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(@resourceset, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}
      format.any {render :text => "SUCCESSFUL"}
      finish = Time.now 
      puts "CONTROLLER EXECUTED: #{(finish - start).to_s}"
    end
  end
 
   def set_endpoint

    params[:read_timeout] = 3000
    current_session = Xplain::Session.load(session[:current_session])
    current_session.set_server params
    current_session.save
    respond_to do |format|
      format.any {render :text => "SUCCESSFUL"}
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
  
  def delete_set
    current_session = Xplain::Session.load(session[:current_session])
    set_to_delete = Xplain::ResultSet.load(params[:id])
    current_session.remove_result_set_permanently(set_to_delete)
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
  
  def all_types
    ruby_expression = "Xplain::SchemaRelation.new(id: \"has_type\", server: @server).image"
    current_session = Xplain::Session.load(session[:current_session])
    server = nil
    if current_session
      server = current_session.server
    end

    @result_set = Xplain::ExecuteRuby.new(code: ruby_expression)
    
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
    
    rs = current_session.execute(search_operation.uniq)
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
  
  def generate_jbuilder(result_set, template_html, component_name = 'DefaultSetWidget', page = 1)
    total_by_page = 20
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
    jbuilder_obj.children Jbuilder.new do |children_json|
      children_json.array!(node.children) do |child_node|
        to_jbuilder(child_node, children_json, set)      
      end      
    end
  end
end
