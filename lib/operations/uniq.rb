module Xplain
  class Uniq < Operation
    def initialize(args={}, &block)
      super(args, &block)
    end
    
    def get_results
      input_set = inputs_working_copy.first
      items_hash = {}
      input_set.children.each do |node|
        #TODO IMPLEMENT A SHALLOW CLONE METHOD
        items_hash[node.item] = Xplain::Node.new item: node.item
      end
      items_hash.values
    end
  end
end