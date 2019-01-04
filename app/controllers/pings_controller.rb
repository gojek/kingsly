class PingsController < ApplicationController
  skip_before_action :http_basic_authenticate

  def show
    render status: 200, body: "pong"
  end
end
