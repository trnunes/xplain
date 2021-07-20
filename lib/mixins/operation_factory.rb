class String
  def to_underscore
    self.gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
    gsub(/([a-z\d])([A-Z])/,'\1_\2').
    tr("-", "_").
    downcase
  end
  def to_camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end
end

module OperationFactory  
  def method_missing(m, *args, &block)
    instance = nil

    klass = Object.const_get m.to_s.to_camel_case

    if !operation_class? klass
      if !auxiliary_function? klass
        raise NameError.new("Auxiliary function #{klass.to_s} does not exist!")
      end      
      return handle_auxiliary_function(klass, *args, &block)
    end

    if args.empty?
      args << {}
    end
    
    target_promisse = nil
    
    if klass::MULTI_SET
      input = args.first
      args[0] = {server: server}
      target_promisse = klass.new(*args, &block)
      Xplain.get_current_workflow.chain(target_promisse, input)
    else
      args.first[:server] ||= server
      target_promisse = klass.new(*args, &block)
    end
    handle_operation_instance(target_promisse)    
    return target_promisse
  end
  
  
  def operation_class?(klass)
    operation_subclasses = ObjectSpace.each_object(Class).select {|space_klass| space_klass < Operation }
    operation_subclasses.include? klass
  end
  
  def auxiliary_function?(function_klass)
    auxiliary_function_subclasses = ObjectSpace.each_object(Class).select {|space_klass| space_klass < AuxiliaryFunction}
    auxiliary_function_subclasses.include? function_klass    
  end
  
  def handle_auxiliary_function(klass, *args, &block)
  end
  
  def handle_operation_instance(target_operation)
  end
end