require 'json'
module Xplain
  module Xplain::NodeWritable
    def save()
      Xplain::exploration_repository.save_node(self)
    end
  end
  
  module WorkflowWritable
    def save()
      Xplain::exploration_repository.save_workflow(self)
    end
  end
  
  module ResultSetWritable
    def save()
      self.id ||= SecureRandom.uuid
      Xplain::exploration_repository.result_set_save(self)
    end
    
    def delete()
      Xplain::exploration_repository.result_set_delete(self)
    end
        
    def self.delete_all()
      Xplain::exploration_repository.result_set_delete_all()
    end
  end
  
  module SessionWritable
    def add_result_set(result_set)
      Xplain::exploration_repository.session_add_result_set(self, result_set)
    end
    
    def load_result_sets
      Xplain::exploration_repository.session_load_result_sets(self)
      return []
    end
    
    def delete
      Xplain::exploration_repository.session_delete(self)
    end
  end
end