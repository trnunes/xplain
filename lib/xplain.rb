require 'set'
require 'forwardable'
require 'mixins/graph_converter'
require 'mixins/operation_factory'
require 'adapters/memory/memory_repository'
require 'mixins/config.rb'
require 'mixins/dsl_callable.rb'
require 'mixins/writable.rb'
require 'mixins/readable.rb'
require 'execution/workflow.rb'

require 'mixins/enumerable'
require 'mixins/relation'
require 'exceptions/missing_relation_exception'
require 'exceptions/repository_connection_error'
require 'exceptions/missing_value_exception'
require 'exceptions/invalid_input_exception'
require 'exceptions/disconnected_operation_exception'
require 'exceptions/missing_auxiliary_function_exception'
require 'exceptions/numeric_item_required_exception'

require 'model/node'
require 'model/edge'
require 'model/item_factory'
require 'model/item'
require 'model/entity'
require 'model/type'
require 'model/literal'
require 'model/schema_relation'
require 'model/path_relation'
require 'model/session'
require 'model/namespace'
require 'model/result_set'
require 'model/remote_set'

require 'model/relation_handler'
require 'model/sequence'

require 'mixins/model_factory'

require 'visualization/visualization'
require 'securerandom'
require 'operations/auxiliary_function'
require 'operations/operation'
require 'operations/set_operation'
require 'operations/group_aux/grouping_relation'
require 'operations/group_aux/by_image'
require 'operations/rank_aux/by_image'
require 'operations/rank_aux/by_text'

require 'repositories/data_server'
require 'repositories/schema_relation_gateway'
require 'repositories/path_relation_gateway'

require 'operations/refine_aux/filter_factory'
require 'operations/refine_aux/generic_filter'
require 'operations/refine_aux/relation_filter'
require 'operations/refine_aux/composite_filter'
require 'operations/refine_aux/in_memory_filter_interpreter'
require 'execution/dsl_parser.rb'

$BASE_DIR = "#{Rails.root}/lib/"
Dir[$BASE_DIR + "operations/*.rb"].each{|f| require f}

require 'operation_factory'

(Dir[$BASE_DIR + "adapters/*/lib/*helper.rb"]).each {|file| require file }
(Dir[$BASE_DIR + "adapters/*/lib/*.rb"] - Dir[$BASE_DIR + "adapters/*/lib/*data_server.rb"] - Dir[$BASE_DIR + "adapters/*/lib/data_server.rb"]).each {|file| require file }
(Dir[$BASE_DIR + "adapters/*/lib/data_server.rb"]).each {|file| require file }
Dir[$BASE_DIR + "adapters/*/lib/*data_server.rb"].each {|file| require file }

module Xplain
  @@base_dir = $BASE_DIR
  
  class << self
    def base_dir=(base_dir_path)
      @@base_dir = base_dir_path
    end
    
    def base_dir
      @@base_dir
    end
  end
end