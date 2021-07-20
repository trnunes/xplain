class Edge
  attr_accessor :origin, :target, :annotations
  def initialize(origin, target, annotations = [])
    @origin, @target = origin, target
    @annotations = annotations
  end
  
  def eql?(edge)
    edge.origin == origin && edge.target == target
  end

  def hash
    origin.hash * target.hash
  end

  alias == eql?
  
  def to_s
    origin.item.inspect + " -> " + target.item.inspect
  end
  
  def inspect
    origin.item.inspect + " -> " + target.item.inspect + " NOTES: " + annotations.map{|note| "\"" + note.to_s + "\""}.join(", ")
  end
  
end