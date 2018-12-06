module AuthHelper
  def http_login
    user = ENV['USERNAME']
    pw = ENV['PASSWORD']
    request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials(user,pw)
  end
end
