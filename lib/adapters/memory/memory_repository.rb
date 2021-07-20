class MemoryRepository
  
  
  attr_accessor :record_intention_only
  def initialize(args ={})
    @record_intention_only = args[:record_intention_only]
    @nodes_hash = {}
    @results_hash = {}
    @intention_index = {}
    @workflow_hash = {}
    @session_hash = {}
    @items_cache = {}
    @operations_cache = {}
    @items_cache_limit = 20000
    @server_cache = {}
    @path_relation_cache = {}
    @namespaces_hash = {}
  end
  
  def save_node(node)
    @nodes_hash[node.id] = node
  end

  def path_relation_save(path_relation)
    @path_relation_cache[path_relation.id] = path_relation
  end

  def path_relation_load(path_relation_id)
    @path_relation_cache[path_relation_id]
  end
  def path_relation_load_all()
    @path_relation_cache.values
  end
  
  def self.set_items_cache_limit(limit)
    @items_cache_limit = limit
  end
  
  def get_server_cache(server)
      if !@server_cache[server.url]
        @server_cache[server.url] = {items_cache:{}, intention_index:{},results_hash:{} }
      end
      @server_cache[server.url]
  end
  
  def save_item(item)
    server = item.server
    items_cache = @items_cache
    if items_cache.keys.size >= @items_cache_limit
      items_cache.delete(item.id)
    end
    items_cache[item.id] = item
  end
  
  def get_item(id)
    item = nil
    @items_cache[id]
    
  end

  def namespace_save(ns)
    @namespaces_hash[ns.uri] = ns
  end
  
  def namespace_find_all
    @namespaces_hash.values
  end

  def namespace_delete_all()
    @namespaces_hash = {}
  end
  
  def load_node(node_id)
    if node_id.nil? || node_id.empty?
      raise ArgumentError.new("The node id must be a non-empty string!")
    end
    @nodes_hash[node_id]
  end
  
  def result_set_find_by_node_id(node_id)
    @results_hash.values.select{|result_set| result_set.include_node?(node_id)}
  end
  
  def result_set_count
    @results_hash.values.size
  end
  
  def save_workflow(workflow)
    @workflow_hash[workflow.id] = workflow
  end
  
  def load_workflow(workflow_id)
    if node_id.nil? || node_id.empty?
      raise ArgumentError.new("The workflow id must be a non-empty string!")
    end
    @workflow_hash[workflow_id]
  end
  
  def result_set_save(resultset, flush_extension = @record_intention_only)
    @results_hash[resultset.id] = resultset
    resultset    
  end
  
  
  def result_set_load(resultset_id)
    if resultset_id.nil? || resultset_id.empty?
      raise ArgumentError.new("The result set id must be a non-empty string!")
    end
    @results_hash[resultset_id]
  end
  
  def session_add_result_set(session, result_set)
    
  end
  
  #TODO remove
  def clear
    @nodes_hash.clear
    @results_hash.clear
    @intention_index.clear
    @workflow_hash.clear
    @session_hash.clear
    @items_cache.clear
    @server_cache.clear
    @operations_cache.clear
    @items_cache_limit = 20000
  end
  
  def session_add_resultset(session, result_set)
    if !@operations_cache[session.id]
      @operations_cache[session.id] = {result_set.intention.to_ruby_dsl_sum => result_set}
    end
    if !@operations_cache[session.id][result_set.intention.to_ruby_dsl_sum]
      @operations_cache[session.id][result_set.intention.to_ruby_dsl_sum] = result_set
    end
  end
  
  def session_get_resultset(session, operation_key)
    
    if session && @operations_cache[session.id]
      @operations_cache[session.id][operation_key]
    end
  end
  
  def session_cache
    @operations_cache
  end
  
  def result_set_load_by_intention(intention_key)
     
    
    if intention_key.nil? || intention_key.to_s.empty?
      raise ArgumentError.new("The result set id must be a non-empty string!")
    end
    intention_hash = get_server_cache(intention_key.server)[:intention_index]
    
    if(intention_key.is_a? Xplain::Operation)
      intention_key = intention_key.to_ruby_dsl_sum
    end
    
    rs = intention_hash[intention_key]
    
    if rs
      puts "Cached ResultSet found!: " << intention_key
    else
      puts "ResultSet not Cached: " << intention_key
    end
    rs
  end
  
  def session_save(session)
   @session_hash[session.id] = session 
  end
  
  def session_find_by_title(title)
    @session_hash.values.select{|s| s.title == title}
  end
  
  def session_load(id)
    @session_hash[id]
  end
  
  def session_delete(session)
    @session_hash.delete(session.id)
  end
  
  def sessions
    @session_hash
  end


end