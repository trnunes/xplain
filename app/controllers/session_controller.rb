require 'timeout'
class SessionController < ApplicationController
  
  def render_template(resource_set, template_path)
    #TODO change to get the template from a resourceset attribute
    #TODO not actually rendering partial within the template
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    template_html = view.render(file: template_path)
    puts "HTML: " << template_html
    template_html
  end
    
  def index
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
    set = Xplain::ResultSet.load(params[:set])
    
    json = Jbuilder.new do |viewJson|
      viewJson.html render_template(set, (view+ '/_'+view+ '.html.erb'))
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
      @resourceset.save
    rescue Exception => e
      puts e.message
      puts e.backtrace
    end
    
    respond_to do |format|
      format.js
      format.json {render :json => generate_jbuilder(@resourceset, render_template(@resourceset, (Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')))}
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
      format.json {render :json => generate_jbuilder(resourceset, render_template(resourceset, default_template_file), nil, items_page)}
      format.any {render :text => "SUCCESSFUL"}
    end    
  end
    
  
  def all_types
    has_type_relation = Xplain::SchemaRelation.new(id: "has_type")

    @result_set = has_type_relation.image
    
    respond_to do |format|


      format.js { render :file => "/session/execute.js.erb" }
      format.json {render :json => generate_jbuilder(@result_set, render_template(@result_set, (Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')))}

    end     
  end
  
  def search
    input = Xplain::ResultSet.load(params[:set])
    search_operation = Xplain::KeywordSearch.new(inputs: input, keyword_phrase:  params[:str].to_s, inplace: true)
    rs = search_operation.execute()
    respond_to do |format|

        format.js { render :file => "/session/execute.js.erb" }
        format.json {render :json => generate_jbuilder(rs, render_template(rs, (Wxplain::Application::DEFAULT_SET_VIEW+ '/_'+Wxplain::Application::DEFAULT_SET_VIEW+ '.html.erb')))}
      
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
    end.target!
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
