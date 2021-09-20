module Xplain
    class Param
        attr_accessor :name, :value
        def initialize(name, value)
            @name = name
            @value = value
        end
    end
end