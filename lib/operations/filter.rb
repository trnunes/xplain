module Xplain
    
    def self.create_filter(input_nodes, filters)
        filter_instances = filters.map do |f|
            create_single_filter(input_nodes, f)
        end

        if filter_instances.size > 1
            return AndFilter.new(filter_instances)
        end
        return filter_instances.first
    end

    def self.create_single_filter(input_nodes, filter)
        if filter.is_a? Hash
            operator, filters = filter.entries.first
            filter_instances = filters.map{|f| self.create_single_filter(input_nodes, f)}
            case operator.to_sym

            when :and
                AndFilter.new(filter_instances)
            when :or
                OrFilter.new(filter_instances)
            else
                raise "Operator \"#{operator}\" not recognized!"
            end
        elsif filter.is_a? Array
            
            relation, operator, value = filter
            operator_instance = create_operator(operator)
            relation_instance = Xplain::Relation.create(relation)
            value_instance, datatype = value
            value_instance = Xplain::Literal.create(value_instance, datatype)
            
            ImageFilter.new(input_nodes, relation_instance, operator_instance, value_instance)
        elsif filter.is_a? String
            Filter.new(input_nodes, filter)
        else
            raise "Filter structure not recognized: \"#{filter.inspect}\""
        end
    end

    def self.create_operator(operator_alias, args =[])
        case operator_alias
        when "="
            Equal.new(args)
        when "<="
            LessThanEqual.new(args)
        when ">="
            GreaterThanEqual.new(args)
        when "<"
            LessThan.new(args)
        when ">"
            GreaterThan.new(args)
        else
            raise "Operator #{operator_alias} not recognized!"
        end
        

    end

    class AndFilter
        attr_accessor :filters
        def initialize(filters)
            @filters = filters
        end

        def filter()
            results = @filters.map do |f|
                f.filter
            end

            intersected_nodes = results[0] || []
            
            results.each do |r|
                intersected_nodes &= r
                
            end

            return intersected_nodes

        end
    end


    class OrFilter
        attr_accessor :filters
        def initialize(filters)
            @filters = filters
        end

        def filter()
            results = @filters.map do |f|
                f.filter
            end

            union_nodes = results[0] || []

            results.each do |r|
                union_nodes |= r
            end

            return union_nodes

        end
    end

    class Filter
        attr_accessor :input_nodes
        def initialize(input_nodes, expression)
            @input_nodes = input_nodes
            @expression = expression

            if @expression.nil?
                raise "Filter requires an expression parameter!"
            end
            begin
                @proc = eval("lambda{#{@expression}}")
            rescue Exception
                raise "There is something wrong with the filter code \"#{@expression}\""
            end
        end

        def filter()
            filtered_nodes = input_nodes.select do |node|
                @proc.call node
            end
            filtered_nodes

        end
    end
    class KeywordFilter
        def intialize(input_nodes, keyword)
            @input_nodes = input_nodes
            @keyword = keyword
        end
        
        def filter()
            result_nodes = []
            input_nodes.each do |node|
                result_nodes += node.breadth_first_search(true){|bfs_node| bfs_node.item.text.downcase.include?(@keyword.to_s.downcase)}
            end
            result_nodes
        end
    end

    class ImageFilter
        attr_accessor :input_nodes, :relation, :operator, :value
        def initialize(input_nodes, relation, operator, value)
            @relation = relation
            @value = value
            @input_nodes = input_nodes.to_a
            binding.pry
            @input_nodes_hash = input_nodes.map{|n|[n.item, n]}.to_h
            @operator = operator
            
        end

        def filter()
            image = Xplain::Pivot.new.get_results(
                input_nodes: @input_nodes, 
                relation: @relation, 
                group_by_domain: true
            )
            
            
            filtered_image = image.select{|n| !n.children.index{|c| operator.compare(c.item, @value)}.nil?}
            # binding.pry
            results = filtered_image.map{|n| @input_nodes_hash[n.item]}.compact
            
            return results
        end

    end

    class Equal
        def initialize(*args)
        end
        def compare(value1, value2)
            # binding.pry
            value1 == value2
        end
    end

    class LessThan
        def initialize(*args)
        end
        def compare(value1, value2)
            # binding.pry
            value1 < value2
        end
    end

    class LessThanEqual
        def initialize(*args)
        end
        def compare(value1, value2)
            value1 <= value2
        end
    end

    class GreaterThan
        def initialize(*args)
        end
        def compare(value1, value2)
            # binding.pry
            value1 > value2
        end
    end

    class GreaterThanEqual
        def initialize(*args)
        end
        def compare(value1, value2)
            value1 >= value2
        end
    end
end