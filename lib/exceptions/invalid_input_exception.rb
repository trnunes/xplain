class InvalidInputException < StandardError
    def initialize(msg = "You should provide a node as input!")
      super
    end
end