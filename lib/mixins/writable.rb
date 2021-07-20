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

  module PathRelationWritable
    def save()
      Xplain::exploration_repository.path_relation_save(self)
    end
  end
  
  module ResultSetWritable
    def save()
      self.id ||= SecureRandom.uuid
      Xplain::exploration_repository.result_set_save(self)
      if Xplain.cache_results?
        Xplain::memory_cache.result_set_save(self)
      end
    end
    
    def update()
      Xplain::exploration_repository.result_set_delete(self)
      Xplain::exploration_repository.result_set_save(self, true)
    end
    
    def delete()
      Xplain::exploration_repository.result_set_delete(self)
    end
        
    def self.delete_all()
      Xplain::exploration_repository.result_set_delete_all()
    end
  end
  
  module NamespaceWritable
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def save()
      Xplain::exploration_repository.namespace_save(self)
    end

    module ClassMethods
      def delete_all
        Xplain::exploration_repository.namespace_delete_all
      end
    end

  end

  module SessionWritable
    def self.included(klass)
      klass.extend(ClassMethods)
    end
    
    module ClassMethods
      def create(params = {})
        id = params[:id] || SecureRandom.uuid
        
        if !params[:server]
          raise "Cannot create a session without a server!"
        end
        server = params[:server]
        server.save
        session = Session.new(id: id, title: params[:title], server: server, view_profile: params[:view_profile])
        
        if Xplain.cache_results?
          Xplain::memory_cache.session_save(session)  
        end
        session.save
        session
      end
    end
    
    def add_result_set(result_set)
      Xplain::exploration_repository.session_add_result_set(self, result_set)
    end
    
    def remove_result_set(result_set)
      Xplain::exploration_repository.session_remove_result_set(self, result_set)
      @result_sets_hash.delete result_set.intention.to_ruby_dsl_sum
    end
    
    def remove_result_set_permanently(result_set)
      remove_result_set result_set
      result_set.delete
    end
    
    def save
      Xplain::exploration_repository.session_save(self)
      if Xplain.cache_results?
        Xplain.memory_cache.session_save(self)
      end

    end
    
    def delete
      Xplain.memory_cache.session_delete(self)
      Xplain::exploration_repository.session_delete(self)
      
    end
  end

  module ProfileWritable
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      #TODO implement
      def create(params = {})
        if params.empty?
          raise "Cannot create an empty profile!"
        end
        profile = Xplain::Visualization::Profile.new(params)
        profile.save
        profile
      end
    end

    def save()
      Xplain::exploration_repository.view_add_profile(self)
    end
  end
end