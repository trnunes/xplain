class RelationFilter < GenericFilter
  include Xplain::FilterFactory
  

  def initialize(&block)
    super &block
    if(@relation.nil?)
      raise MissingRelationException
    end
    if(@values.nil? || @values.compact.empty?)
      raise MissingValueException
    end
  end

  def get_relation
    return @relation
  end

  def get_values
    return nil if @values.nil? || @values.empty?
    return @values
  end
end
