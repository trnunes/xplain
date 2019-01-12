class WelcomeController < ApplicationController
  
  def index
    
    session[:current_session] ||= Xplain::Session.new(SecureRandom.uuid, "Unnamed")


  end
end
