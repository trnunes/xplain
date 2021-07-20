class WelcomeController < ApplicationController
  protect_from_forgery except: :index
  def index
    
    
    begin
      @current_session = Xplain::Session.create(title: "Unnamed", server: Xplain.default_server, view_profile: Xplain::Visualization.current_profile)
      
    rescue Exception => e
      puts e.backtrace
      puts e.message
      
    end

    

  end
end
