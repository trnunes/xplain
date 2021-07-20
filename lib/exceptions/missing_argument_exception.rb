class MissingArgumentException < StandardError
  def initialize(arg_name, operation_name)
    super "you should provide a #{arg_name} for #{operation_name} operation!"
  end
end