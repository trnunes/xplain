class Promisse
  attr_accessor :operation_klass, :args, :definition_block
  def initialize(operation_klass, *args, &block)
    @operation_klass = operation_klass
    @args = args
    @definition_block = block
  end
  
  def set_operation_input(input)
    @args[0] = input
  end
  
  def execute()
    operation = 
    if @auxiliar_function
      @klass.new(@args, @auxiliar_function, &block)
    else
      @klass.new(@args, &block)
    end
    operation.execute
  end
  
  def method_missing(m, *args, &block)
    instance = nil
    klass = Object.const_get m.capitalize
    operation_subclasses = ObjectSpace.each_object(Class).select {|space_klass| space_klass < Operation }
    if operation_subclasses.include? klass
      workflow = Xplain.get_current_workflow
      args.unshift(self)
      if args[1].nil?
        args[1] = @server
      end
      target_promisse = Promisse.new(klass, *args, &block)
      workflow.chain(self, target_promisse)
      return target_promisse
    else
      @auxiliar_function = klass.new(*args, &block)
    end
  end
end