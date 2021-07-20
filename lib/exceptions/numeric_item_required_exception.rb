class NumericItemRequiredException < StandardError
    def initialize(msg = "The item must be a numeric literal!")
      super
    end
end