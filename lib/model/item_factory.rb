module ItemFactory
  
  
  def create(params = {})
    
    if params[:id]      
      item = Xplain::memory_cache.get_item(params[:id])
      if !item
        item = self.new(params)
        Xplain::memory_cache.save_item(item)
      end
      
      item
      
    end
  end

end