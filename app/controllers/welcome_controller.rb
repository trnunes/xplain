class WelcomeController < ApplicationController
  
  def index
    # Xplain::ResultSet.load_all.each{|rs| rs.delete}
    session[:current_session] = Xplain::Session.new(SecureRandom.uuid, "Unnamed")


  end
end
