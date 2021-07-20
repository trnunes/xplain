module Xplain::DslCallable
    def method_missing(m, *args, &block)

    instance = nil
    
    operation_files = Dir[Xplain.base_dir + "operations/*.rb"]
    
    target_operation_file = Xplain.base_dir + "operations/" + m.to_s.to_underscore + ".rb"
    
    if operation_files.include? target_operation_file
      load target_operation_file
      klass = Object.const_get "Xplain::" + m.to_s.to_camel_case
      if args.nil? || args.empty?
        args = {}
      elsif args[0].is_a? Hash 
         args = args[0]
      else
        args = {:inputs => args}
      end
       
      if !args[:inputs]
        args[:inputs] = []
      elsif !args[:inputs].is_a? Array
        args[:inputs] = [args[:inputs]]
      end
      
      args[:inputs] << self    
      target_promisse = klass.new(args, &block)
          
      return target_promisse

    else
      module_name = ""
      aux_function_files = []
      target_aux_function_file = ""
      
      if self.is_a? AuxiliaryFunction
        module_name = self.class.name.gsub("Xplain::", "").split("::").first
        aux_function_files = Dir[Xplain.base_dir + "operations/#{module_name.to_underscore}/*.rb"]
        target_aux_function_file = Xplain.base_dir + "operations/#{module_name.to_underscore}/#{m.to_s.to_underscore}.rb"
      else
        class_name_no_module = self.class.name.to_s.gsub("Xplain::", "")
        aux_function_files = Dir[Xplain.base_dir + "operations/" + class_name_no_module.to_underscore  + "_aux/*.rb"]
        target_aux_function_file = Xplain.base_dir + "operations/" + class_name_no_module.to_underscore  + "_aux/#{m.to_s.to_underscore}.rb"
        module_name = class_name_no_module.to_camel_case + "Aux"
      end    
      if aux_function_files.include? target_aux_function_file
        load target_aux_function_file
        klass = Object.const_get module_name + "::" + m.to_s.to_camel_case
        handle_auxiliary_function(klass, *args, &block)
      else
        super
      end
    end
  end
  
  def handle_auxiliary_function(klass, *args, &block)
    return klass.new(*args, &block)
  end

end