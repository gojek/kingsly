class ApplicationController < ActionController::Base
  http_basic_authenticate_with name: ENV['USERNAME'], password: ENV['PASSWORD']
end
