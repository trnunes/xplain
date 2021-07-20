class Operation
  attr_accessor :args
  def initialize(args ={})
    @args = args
  end
  
  def input
    @args[:input] || []
  end
  def eql?(operation)
    operation.args == args
  end
  
  def hash
    args = @args.clone
    @args.hash
  end
  
  def to_s
    @args.inspect
  end
  
  alias == eql?
end

class SetOperation < Operation
end

o1 = Operation.new(id: "rootOp")
o2 = Operation.new(id: "op1", input: [o1], arg1: "arg1", arg2: "arg2", arg3: "arg3")
o3 = Operation.new(id: "op2", input: [o2], arg1: "arg4", arg2: "arg5", arg3: "arg6")

o4 = Operation.new(id: "op4", input: [o1], arg1: "arg7", arg2: "arg8", arg3: "arg9")
o5 = Operation.new(id: "op5", input: [o4], arg1: "arg10", arg2: "arg11", arg3: "arg12")

o6 = Operation.new(id: "diff", input: [o5, o3], arg1: "arg13", arg2: "arg14", arg3: "arg15")

new_bindings = {"op2" => {arg1: "newArg1", arg2: "newArg2"}, "op3" => {arg1: "newarg4"}}


#TODO put the algorithm to use
def execute(operation, new_bindings)
  operation_inputs = []
  if operation.input.empty?
    operation_inputs = []
  else
    operation_inputs = operation.input.map{|i| execute(i, new_bindings)}    
  end
  operation_args = operation.args

  if(new_bindings.has_key? operation.args[:id])
    operation_args = operation_args.merge(new_bindings[operation.args[:id]]){|param, value, new_value| new_value}
  end
  operation_args[:input] = operation_inputs
  return Operation.new(operation_args)
end


