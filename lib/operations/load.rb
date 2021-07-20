module Xplain
  class Load < Operation
    
    def initialize(args={}, &block)    
      super(args, &block)
      @set_id = args[:id]
    end
    
    def get_results()
      Xplain::ResultSet.load(@set_id)
      
    end
  end
end