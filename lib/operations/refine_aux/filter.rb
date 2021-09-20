module Xplain
    class AndFilter
        attr_acessor :children
        def initialize(params = {})
            @children = params[:children] || []
        end

        def filter()
            results = @children.map do |f|
                f.filter
            end

            intersected_nodes = results[0] || []

            results.each do |r|
                r &= intersected_nodes
            end

            return intersected_nodes

        end
    end


    class OrFilter
        attr_acessor :children
        def initialize(params = {})
            @children = params[:children] || []
        end

        def filter()
            results = @children.map do |f|
                f.filter
            end

            union_nodes = results[0] || []

            results.each do |r|
                r |= union_nodes
            end

            return union_nodes

        end
    end

    class Filter
        attr_acessor :input_nodes
        def initialize(params = {})
            @input_nodes = params[:input_nodes]

            @expression = params[:expression]
            if @expression.nil?
                raise "Filter requires an expression parameter!"
            end
        end

        def filter()
            filtered_nodes = input_nodes.select do |node|
                eval("lambda{#{@expression}}").call node
            end
            filtered_nodes

        end


    end
end