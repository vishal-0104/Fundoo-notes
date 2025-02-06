require 'jwt'

class JsonWebToken
  SECRET_KEY = ENV['SECRET_KEY']
  def self.encode(payload, exp = 7.days.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    body, = JWT.decode(token, SECRET_KEY)
    HashWithIndifferentAccess.new(body)
    
  rescue JWT::ExpiredSignature
    nil
  rescue JWT::DecodeError
    nil
  end
end