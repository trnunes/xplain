class WelcomeController < ApplicationController
  
  def index
    
    session[:current_session] = Xplain::Session.create(title: "Unnamed").id

  end
end
