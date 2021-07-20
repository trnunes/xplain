class MissingValueException < StandardError
  def initialize(msg = "You should provide at least one filtering value!")
    super
  end
end