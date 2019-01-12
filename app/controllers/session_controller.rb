require 'timeout'
class SessionController < ApplicationController
  before_filter :load_temp_session
  
  def load_temp_session
    if !session[:current_session]
      session[:current_session] = Xplain::Session.new(SecureRandom.uuid, "Unnamed")
    end
  end
  
  def render_template(template_path, context={})
    #TODO change to get the template from a resourceset attribute
    #TODO not actually rendering partial within the template
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    template_html = view.render(file: template_path)
    puts "HTML: " << template_html
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
      @resourceset = eval(params[:exp].gsub("%23", "#"))
      session[:current_session] << @resourceset
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
    Xplain.set_default_server params

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
    @section_list.delete(session[:current_session].title)
    view = ActionView::Base.new(ActionController::Base.view_paths, {section_list: @section_list})
    template_html = view.render({partial: "session/section_list"})
    
    respond_to do |format|
      format.json{render :json => Jbuilder.new{|set_json| set_json.html template_html}.target!}
    end
  end
    
  def save_session
    name = params[:name]
    if !name.empty? && name != session[:current_session].title
      new_session = Xplain::Session.new(SecureRandom.uuid, name)
      session[:current_session].each_result_set_tsorted do |rs|
        new_session << rs
      end
      if session[:current_session].title == "Unnamed"
        session[:current_session].delete
      end
      session[:current_session] = new_session
    end
    
    respond_to do |format|
      format.json{render :json => Jbuilder.new(){|json| json.message "Success"}.target!}
    end 
  end
  
  def all_types
    ruby_expression = "Xplain::SchemaRelation.new(id: \"has_type\").image"

    @result_set = Xplain::ExecuteRuby.new(code: ruby_expression).execute
    
    respond_to do |format|


      format.js { render :file => "/session/execute.js.erb" }
      format.json {render :json => generate_jbuilder(@result_set, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}

    end 
  end
  
  def load_all_resultsets
    begin
      all_result_sets_ordered = session[:current_session].each_result_set_tsorted(exploration_only: true)
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
    
    if params[:name]
      session_name = params[:name]
      session_found = Xplain::Session.find_by_title(session_name).first
    end

    respond_to do |format|
      if session_found
        session[:current_session] = session_found
        begin
          result_sets_json = "[#{session_found.each_result_set_tsorted(exploration_only: true).map{|rs| generate_jbuilder(rs, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}.join(", ")}]"
        rescue Exception => e
          puts e.message
          puts e.backtrace
        end
        format.json {render :json =>  result_sets_json}
      else
        format.json {render :json =>  "errorMessage: \"Session #{params[:name]} does not exist!\""}
      end
    end

  end
  
  def search
    input = Xplain::ResultSet.load(params[:set])
    search_operation = Xplain::KeywordSearch.new(inputs: input, keyword_phrase:  params[:str].to_s, inplace: true, visual: true)
    
    rs = search_operation.execute().uniq!
    respond_to do |format|

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(rs, render_template(Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')).target!}
      
    end
  end

    
  def new
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
          to_jbuilder(node, ext_json)
          
        end
      end
    end
    json
  end
  
  
  def to_jbuilder(node, jbuilder_obj)
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
    jbuilder_obj.type node.item.class.to_s
    jbuilder_obj.inverse node.item.inverse?.to_s if node.item.respond_to? :inverse?
    jbuilder_obj.children Jbuilder.new do |children_json|
      children_json.array!(node.children) do |child_node|
        to_jbuilder(child_node, children_json)      
      end      
    end
  end
end
