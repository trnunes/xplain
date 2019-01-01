class WelcomeController < ApplicationController
  
  def index
    
    Xplain::ResultSet.load_all.each{|rs| rs.delete}

  end
end
