class SessionController < ApplicationController
  
    
  def index
    s = Xset.new do |s|
      s.server = SERVER
      s.id = "original"
    end
    s.save
    @sets = [s]
  end
  
  def execute
    puts "EXPRESSION: " << params[:exp]
    
    @resourceset = eval(params[:exp])
    @resourceset.paginate(1, 5)    
    @resourceset.save
    
    respond_to do |format|
      format.js
    end    
  end
  
  def nextpage
    @resourceset = Xset.load(params[:set])
    page_to_display = params[:page].to_i
    
    @resourceset.paginate(page_to_display, 5)
    respond_to do |format|
      format.js
    end
  end
  
  def renderdomain
    @resourceset = Xset.load(params[:set])
    respond_to do |format|
      format.js
    end
    
  end
  
  def new
  end
end
