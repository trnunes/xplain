module Xplain
  #TODO implement a save method tracking updates and also result-set updates
  class Session
    include Xplain::SessionWritable
    extend Xplain::SessionReadable
    
    attr_accessor :id, :title, :result_sets
    
    def initialize(session_id, title=nil)
      @id = session_id
      @title = title
      @title ||= session_id.gsub("_", " ")
      @result_sets = []
    end
    
    def <<(result_set)
      
      resulted_from_array = [result_set]
      #TODO Keep cached in memory
      while !resulted_from_array.empty?
        resulted_from_array.each do |r_from|
          
          if r_from.id.nil?
            r_from.save
          end
          
          add_result_set(r_from)
          # @result_sets << r_from
        end
        resulted_from_array = resulted_from_array.map{|r| r.resulted_from}.flatten(1)
      end
      
    end
    def empty?
      Xplain::ResultSet.find_by_session(self).empty?
    end

    def each_result_set_tsorted(options={}, &block)
      Xplain::ResultSet.find_by_session(self, options).each &block
    end
    
  end
end