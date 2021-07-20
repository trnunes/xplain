require 'set'
module Xplain
  module Enumerable
    
    def get_cursor(level, page_size)
      Cursor.new(self, [], [], level, page_size)
    end
    
    def each(&block)
    end
    
    def each_level(&block)
    end
    
    def count_levels
    end
    
    def get_level(level, parents_restriction=[], children_restriction= [], offset=0, limit=-1)
    end

    def leaves
    end
    
    def each_domain(&block)
    end
    
    def each_image(&block)
    end

    def each_path(&block)
    end
    
    def breadth_first_each(item, current_path = [], &block)
    end

    def depth_first_each(item, current_path = [], &block)
    end
  end
  
  class Cursor
    attr_accessor :window_size, :relation, :pages_cache
    def initialize(relation, parents_restriction= [], children_restriction = [], level=2, window_size = 20)
      @pages_cache = {}
      @relation = relation
      @level = level
      @parents_restriction = parents_restriction
      @children_restriction = children_restriction
      reset(window_size)
    end
  
    def paginate(window_size)
      reset(window_size)
    end
  
    def each(&block)
      @relation.get_level(@level, @parents_restriction, @children_restriction).each &block
    end
  
    def reset(window_size=20)
      @page = 0
      @offset = 0
      if @window_size != window_size
        @pages_cache = {}
      end
      @window_size = window_size
      @limit = window_size    
    end
  
    def next_page

      level_items = @relation.get_level(@level, @parents_restriction, @children_restriction, @offset, @limit)
      if !level_items.to_a.first.is_a?(Literal) && level_items.respond_to?(:uniq)
        level_items.uniq!
      end

      @page += 1
      @offset += @limit
      @pages_cache[@page] = level_items
      level_items
    end
  
    def get_page(page_number)
      if(@pages_cache.has_key?(page_number))
        return @pages_cache[page_number]
      end
      return [] if(page_number < 1)
    
      pg_offset = 0
    
      (page_number - 1).times{|pg| pg_offset += @limit}
    
      level_items = @relation.get_level(@level, @parents_restriction, @children_restriction, pg_offset, @limit)
      if !level_items.to_a.first.is_a?(Literal) && level_items.respond_to?(:uniq)
        level_items.uniq!
      end
    
      @pages_cache[page_number] = level_items
      level_items
    end
  end

end
