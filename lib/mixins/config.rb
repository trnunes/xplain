module Xplain
  @@current_workflow = nil
  @@exploration_repository = MemoryRepository.new
  @@cache_results= false
  @@persist_extensions = false
  @@memory_cache = MemoryRepository.new
  
  class << self
    def base_dir=(base_dir_path)
      @@base_dir = base_dir_path
    end
    
    def persist_extensions=(bool)
      @@persist_extensions = bool
    end
    def persist_extensions?
      @@persist_extensions
    end
    
    def base_dir
      @@base_dir
    end
    
    def cache_results?
      @@cache_results
    end
    
    def cache_results=(bool)
      @@cache_results = bool
    end
    
    def memory_cache
      @@memory_cache
    end
      
    def get_current_workflow
      @@current_workflow ||= Workflow.new
      @@current_workflow
    end
  
    def exploration_repository
      @@exploration_repository
    end 
    
    def new_workflow
      @@current_workflow = Workflow.new
      @@current_workflow
    end
  
    def reset_workflow
      @@current_workflow = Workflow.new
      @@current_workflow
    end
    
    def set_default_server(server_params)
      if server_params.is_a? Hash
        klass = server_params[:class]
        klass = eval(klass) if klass.is_a? String
        @@default_server = klass.new(server_params)
      else
        @@default_server = server_params
      end
      @@default_server
    end
    
    def set_exploration_repository(repository_params)
      if repository_params.is_a? Hash
        klass = repository_params[:class]
        @@exploration_repository = klass.new(repository_params)
      else
        @@exploration_repository = repository_params
      end
      @@exploration_repository
    end
    
    def default_server
      @@default_server
    end
  end
    

  #Config
  # 1 config data adapter
  # 2 config exploration adapter
  # 3 config visualization
  # 4 config relations label
  # 6 config types query
  
    
end


class String
  
  def to_underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end


  def escape()
    self.gsub('"', "$PLIC").gsub("'", "$APSTR");
    
  end

  def unescape()
    self.gsub("$PLIC", '"').gsub("$APSTR", "'");
  end
  
  def to_camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end