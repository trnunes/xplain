module Xplain
  class Literal
  
    attr_accessor :value, :datatype, :parent, :children, :text_relation, :server
  
    def initialize(value, type=nil, server=nil)
      @value = value
      if @value.is_a? String
        @value = @value.unescape
      end
      @datatype = type
      @server = server
      @children = []
      @text_relation = "xplain:has_text"
    end
    
    def <=>(other_literal)
      if other_literal.value.class == self.value.class
         self.value <=> other_literal.value
      else
        self.text <=> other_literal.text
      end
    end

    def copy
      self_copy = Literal.new(@value, @datatype)
      self_copy
    end
    
    def eql?(literal)
      literal.is_a?(self.class) && literal.value == @value
    end
    
    def hash
      @value.hash
    end
    
    def numeric?
      return true if self.text =~ /\A\d+\Z/
      true if Float(self.value) rescue false
    end

    alias == eql?
    
    def text
      @value.to_s
    end    
  
    def to_s
      "Literal: " + @value.to_s
    end
  
    def inspect
      to_s
    end
  end
end