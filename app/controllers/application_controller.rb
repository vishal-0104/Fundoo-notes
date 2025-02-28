class ApplicationController < ActionController::Base
  # Ensure only modern browsers are supported (for web-based apps)
  allow_browser versions: :modern

  # # Apply authentication for API requests
  # before_action :authenticate_request

  # def authenticate_request
  #   header = request.headers['Authorization']
  #   return render json: { error: 'Token missing' }, status: :unauthorized unless header

  #   token = header.split(' ').last
  #   decoded = JsonWebToken.decode(token)

  #   if decoded
  #     @current_user = User.find(decoded[:user_id])
  #   else
  #     render json: { error: 'Invalid token' }, status: :unauthorized
  #   end
  # end

  before_action :authenticate_user!
  before_action :initialize_redis
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  def authenticate_user!
    token = request.headers['Authorization']&.split(' ')&.last
  
    unless token
      render json: { error: 'Unauthorized, token missing' }, status: :unauthorized
      return
    end
  
    decoded_token = JsonWebToken.decode(token)
    unless decoded_token
      render json: { error: 'Unauthorized, invalid token' }, status: :unauthorized
      return
    end
  
    @current_user = User.find_by(id: decoded_token[:user_id])
    
    unless @current_user
      render json: { error: 'User not found' }, status: :unauthorized
      return
    end
  end
  

  private

  def decoded_token
    token = request.headers['Authorization']&.split(' ')&.last
    JsonWebToken.decode(token) if token
  end

  def initialize_redis
    $redis ||= Redis.new(host: "localhost", port: 6379)
  end
end