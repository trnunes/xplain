
module Xplain
  class Entity < Item
    
    def initialize(id, text="")
      if id.is_a? Hash
        super(id)
      else      
        super(id: id, text: text)
      end
    end
  end
end
