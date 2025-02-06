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
  protect_from_forgery with: :null_session, if: -> { request.format.json? }

  def authenticate_user!
    header = request.headers["Authorization"]
    token = header.split(" ").last if header
    decoded = JsonWebToken.decode(token)
    @current_user = User.find(decoded[:user_id]) if decoded
  rescue
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
  

  def current_user
    @current_user ||= User.find_by(id: decoded_token[:user_id]) if decoded_token
  end

  private

  def decoded_token
    token = request.headers['Authorization']&.split(' ')&.last
    JsonWebToken.decode(token) if token
  end

end