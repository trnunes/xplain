class HelpController < ApplicationController
  def index
    @operation = params[:operation]
    @div_id = params[:div]
    if(@operation)
      @div_id ||= @operation + "_help"
    end

    
    respond_to do |format|
      format.js do 
        if @operation
          render :action => 'operation_help'
        else
          render :action => 'help'
        end
        
      end
    end   
    
  end
  
end