module ItemFactory
  
  
  def create(params = {})
    
    if params[:id]      
      item = Xplain::memory_cache.get_item(params[:id])
      if !item
        item = params[:class].new(params)
        Xplain::memory_cache.save_item(item)
      end
      
      item
      
    end
  end

end