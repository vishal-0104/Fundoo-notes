
require_relative 'rabbitmq_publisher'  # Ensure the file is loaded

class UsersService
  class InvalidEmailError < StandardError; end
  class InvalidPasswordError < StandardError; end
  class InvalidOtpError < StandardError; end

  @@otp = nil
  @@otp_generated_at = nil

  def self.create_user(params)
    begin
      user = User.new(params)
  
      if user.save
        Rails.logger.info("✅ User created successfully: #{user.email}")
        { success: true, user: user }
      else
        Rails.logger.error("❌ User creation failed: #{user.errors.full_messages}")
        { success: false, errors: user.errors.to_hash }  # Return a hash instead of an array
      end
    rescue StandardError => e
      Rails.logger.error("⚠️ Unexpected Error during user creation: #{e.message}")
      { success: false, error: "Something went wrong: #{e.message}" }
    end
  end
  
  

  def self.authenticate_user(params)
    user = User.find_by(email: params[:email])
    
    raise InvalidEmailError, "Invalid email" unless user
    raise InvalidPasswordError, "Invalid password" unless user.authenticate(params[:password])
  
    token = JsonWebToken.encode(user_id: user.id) # Generate JWT token
    { success: true, token: token }
  end
  

  def self.forgot_password(email)
    begin
      Rails.logger.info("🔍 Looking for user with email: #{email}")
  
      user = User.find_by(email: email)
      raise InvalidEmailError, "User with this email does not exist" if user.nil?
  
      @@otp = generate_otp
      @@otp_generated_at = Time.current
      Rails.logger.info("🔢 OTP generated: #{@@otp}")
  
      # Publish to RabbitMQ
      Rails.logger.info("📨 Sending OTP to RabbitMQ queue...")
      RabbitMQPublisher.publish("email_queue", { event: "forgot_password", email: user.email, otp: @@otp })
      
      Rails.logger.info("✅ OTP request successfully sent to queue")
      { success: true, message: "OTP request sent to queue", otp: @@otp }
    rescue InvalidEmailError => e
      Rails.logger.error("❌ Error: #{e.message}")
      { success: false, error: e.message }
    rescue Bunny::Exception => e
      Rails.logger.error("🐰 RabbitMQ Error: #{e.message}")
      { success: false, error: "RabbitMQ connection failed" }
    rescue StandardError => e
      Rails.logger.error("⚠️ Unexpected Error: #{e.message}")
      { success: false, error: "Something went wrong: #{e.message}" }
    end
  end

  def self.reset_password(user_id, rp_params)
    raise InvalidOtpError, "OTP has not been generated" if @@otp.nil?

    if rp_params[:otp].to_i == @@otp && (Time.current - @@otp_generated_at < 1.minute)
      user = User.find_by(id: user_id)
      if user
        user.update(password: rp_params[:new_password])
        @@otp = nil  # ✅ Reset OTP after successful password change
        return { success: true }
      else
        return { success: false, errors: "User not found" }
      end
    else
      return { success: false, errors: "Invalid OTP" }
    end
  rescue InvalidOtpError => e
    { success: false, error: e.message }
  end

  private

  def self.generate_otp
    rand(100000..999999) # Generates a 6-digit OTP
  end
end
