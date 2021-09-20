
module Xplain
  class Entity < Item
    
    def initialize(id, text="")
      if id.is_a? Hash
        super(id)
      else      
        super(id: id, text: text)
      end
    end

    def to_h
      return {
        id: @id,
        type: self.class.to_s,
        server: @server.id
      }
    end
  end
end
