class WelcomeController < ApplicationController
  protect_from_forgery except: :index
  def index
    
    
      
      session[:current_session] = Xplain::Session.create(title: "Unnamed").id
    

  end
end
