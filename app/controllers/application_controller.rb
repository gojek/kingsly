class ApplicationController < ActionController::Base
  before_action :http_basic_authenticate

  def http_basic_authenticate
    authenticate_with_http_basic do |name, password|
      name == ENV['USERNAME'] && password == ENV['PASSWORD']
    end
  end
end
