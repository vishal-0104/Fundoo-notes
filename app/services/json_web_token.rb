require 'jwt'

class JsonWebToken
  SECRET_KEY = ENV['SECRET_KEY']
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY, 'HS256')
  end
end