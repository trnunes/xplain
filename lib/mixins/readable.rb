module Xplain
  
  module Xplain::NodeReadable
    def load(id)
      return nil if id.to_s.empty?
      Xplain::exploration_repository.load_node(id)      
    end
  end
  
  module WorkflowReadable
    def load(id)
      return nil if id.to_s.empty?
      Xplain::exploration_repository.load_workflow(id)      
    end
  end

  module DataServerReadable
    def load(id)
      return nil if id.to_s.empty?
      Xplain::exploration_repository.load(id)
    end

    def load_all
      Xplain::exploration_repository.load_all()
    end
  end

  module ResultSetReadable
    def load_intention(id)
      rs = load(id)
      rs.intention if rs
    end
    
    def load(id)
      return nil if id.to_s.empty?
      # result_set = Xplain::memory_cache.result_set_load(id)
      # if !result_set
        result_set = Xplain::exploration_repository.result_set_load(id)
        # if Xplain.cache_results?
          # Xplain::memory_cache.result_set_save(result_set)
        # end 
      # end
      
      result_set
    end
    
    def find_by_node_id(node_id)
      result_sets = Xplain::memory_cache.result_set_find_by_node_id(node_id)
      
      if result_sets.empty?
        result_sets = Xplain::exploration_repository.result_set_find_by_node_id(node_id) 
      end
      result_sets
    end
   #TODO Document options
    def find_by_session(session, options = {})
      sets = Xplain::exploration_repository.result_set_find_by_session(session, options)
      sets.map{|set| Xplain::memory_cache.result_set_load(set.id) || Xplain::memory_cache.result_set_save(set)}
      
    end
    
    def count
      Xplain::exploration_repository.result_set_count
    end
    
    def load_all
      Xplain::exploration_repository.result_set_load_all
    end
    
    def load_all_tsorted
      Xplain::ResultSet.topological_sort Xplain::exploration_repository.result_set_load_all
    end
    
    def load_all_exploration_only
      Xplain::exploration_repository.result_set_load_all(exploration_only: true)
    end
    
    def load_all_tsorted_exploration_only
      all_rs = Xplain::exploration_repository.result_set_load_all(exploration_only: true)
      Xplain::ResultSet.topological_sort all_rs 
    end
  end

  module PathRelationReadable
    def self.included(klass)
      klass.extend(ClassMethods)
    end
    
    #TODO refactor other readables and writables such this one
    module ClassMethods
      def load(id)
      return nil if id.to_s.empty?
        path_relation = Xplain::memory_cache.path_relation_load(id)
        if !path_relation
          path_relation = Xplain::exploration_repository.path_relation_load(id)
          Xplain::memory_cache.path_relation_save(path_relation)
        end
        path_relation
      end

      def find_all

        path_relations = Xplain::exploration_repository.path_relation_load_all()

        path_relations.each{|p_relation| Xplain::memory_cache.path_relation_save(p_relation)}
        path_relations
      end

    end
  end

  module NamespaceReadable
    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def load_all()
        Xplain::exploration_repository.namespace_find_all
      end
    end
  end

  module SessionReadable
    def self.included(klass)
      klass.extend(ClassMethods)
    end
    
    #TODO refactor other readables and writables such this one
    module ClassMethods
      def load(id)
      return nil if id.to_s.empty?
        session = Xplain::memory_cache.session_load(id)
        if !session
          session = Xplain::exploration_repository.session_load(id)
          if session
            Xplain::memory_cache.session_save(session)
          end
        end
        session
      end
      
      def find_by_title(title)
        sessions = Xplain::exploration_repository.session_find_by_title(title)
        sessions.each{|s| Xplain::memory_cache.session_save(s)}
        sessions
      end
      
      def list_titles
        Xplain::exploration_repository.session_list_titles
      end
    end

  end

  module ProfileReadable
    def load(id)
      return nil if id.to_s.empty?
      Xplain::exploration_repository.load_profile(id)
    end

    def find_by_name(profile_name)
      Xplain::exploration_repository.load_profile_by_name(profile_name)
    end
    
    def list()
      Xplain::exploration_repository.find_profiles.sort{|p1, p2| p1.name <=> p2.name}
    end
  end


end