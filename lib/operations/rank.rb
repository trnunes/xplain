class Xplain::Rank < Xplain::Operation
  
  def initialize(args = {}, &block)
    super(args, &block)
    
    @multiplier = (args[:order] == :desc) ? -1:1
  end
  
  def get_results()
    set_to_rank = inputs_working_copy.first
    @level ||= set_to_rank.count_levels
    sorting_items_parents = set_to_rank.get_level(@level - 1)
    
    if(@auxiliar_function)
      ranking_items = set_to_rank.get_level(@level)
      @auxiliar_function.prepare(ranking_items)
    end
    
    sorting_items_parents.each do |parent_item|
      children = parent_item.children
      begin
        children.sort! do |c1, c2|
          if (@auxiliar_function)
            
            @multiplier * @auxiliar_function.compare(c1, c2)
          else
            @multiplier * (c1 <=> c2)
          end  
        end
      rescue Exception => e
        puts "Something is wrong with the ranking."
      end
      
      parent_item.children = children 
    end
    set_to_rank.get_level(2)
  end
end