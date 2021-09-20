require 'date'

module Xplain
  class Literal
  
    attr_accessor :value, :datatype, :parent, :children, :text_relation, :server
    def self.create(value, datatype="")
      l_value = 
        if datatype.to_s.include?("int")
          value.to_i
        elsif datatype.to_s.include?("decimal")
          value.to_f
        elsif datatype.to_s.include?("boolean")
          value == "true"
        elsif datatype.to_s.include?("date")
          Date.parse(value)
        elsif datatype.to_s.include?("time")
          DateTime.parse(value)
        elsif datatype.to_s.include?("gYear")
          value.to_i
        elsif datatype.to_s.include?("float")
          value.to_f
        elsif datatype.to_s.include?("double")
          value.to_f
        elsif datatype.to_s.include?("long")
          value.to_i
        elsif datatype.to_s.include?("short")
          value.to_i
        elsif datatype.to_s.include?("string")
          value.to_s
        else
          self.convert_value(value)
        end
      if datatype.to_s.empty?
        # binding.pry
        datatype = infer_datatype(value)
      end
      Xplain::Literal.new(value: l_value, datatype: datatype)
    end

    def self.infer_datatype(value)
      case value.class
      when Fixnum
        "xsd:integer"
      when Float
        "xsd:decimal"
      when Date
        "xsd:date"
      when DateTime
        "xsd:time"
      else
        "xsd:string"
      end
    end

    def self.convert_value(value)
      converted_value = 
        begin
          Integer(value.to_s)
        rescue => exception
          begin
            Float(value.to_s)
          rescue => exception
            begin
              Date.parse(value.to_s)
            rescue => exception
              value.to_s
            end
          end
        end
      # binding.pry
      converted_value
    end

    def initialize(params)
      @value = params[:value] || params[:id]
      if @value.is_a? String
        #only for test purposes with typed literals (RDF.rb bug), correct in RDF.rb and remove
        @value = @value.unescape
        value, @datatype = @value.split("^^")
        # binding.pry
        if @datatype
          @value = self.class.create(value.gsub("\"", ""), @datatype).value
          # binding.pry
        end
        # binding.pry
        

      end
      @datatype ||= params[:datatype]
      @server = params[:server]
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

    def >(other_literal)
      self.value > other_literal.value
    end

    def >=(other_literal)
      self.value >= other_literal.value
    end

    def <(other_literal)
      self.value < other_literal.value
    end

    def <=(other_literal)
      self.value <= other_literal.value
    end

    def id
      value.to_s
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
    def to_h
      return {
        id: @value.to_s,
        type: self.class.to_s,
        datatype: @datatype.to_s
      }

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