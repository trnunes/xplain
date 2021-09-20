module Xplain
    class WorkflowNode
        attr_accessor :id, :params, :input_nodes
        
        def initialize(params)
            if params.select{|p| p.name == :operation}.empty?
                raise "The WorkflowNode requires an operation!"
            end
            @input_nodes = params.select{|p| p.name == :inputs} || []
            params.delete_if{|p| p.name == :inputs}
            @params = params
            
        end

        def add_input(node)
            @input_nodes.append(node)
        end

        def execute
            params_hash = {}
            # binding.pry

            input_sets = []
            if !@input_nodes.empty?
                input_sets = @input_nodes.first.value.map{|input_op| input_op.execute }
            end
            params_hash[:inputs] = input_sets


            @params.each do |param|
                params_hash[param.name] = param.value
            end
            
            #handle aux functions
            operation_instance = eval("Xplain::#{params_hash[:operation]}").new()
            binding.pry
            operation_instance.execute_eager(params_hash)

        end

        
        
    end
end