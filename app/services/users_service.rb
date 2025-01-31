class UsersService

  class InvalidEmailError < StandardError
  end
  class InvalidPasswordError < StandardError
  end
  class InvalidOtpError < StandardError 
  end

  @@otp = nil

  def self.create_user(params)
    user = User.new(params)
    if user.save
      { success: true, user: user }
    else
      { success: false, errors: user.errors }
    end
  end

  def self.authenticate_user(params)
    user = User.find_by(email: params[:email])

    raise InvalidEmailError, "Invalid email" if user.nil?

    unless user.authenticate(params[:password])
      raise InvalidPasswordError, "Invalid password"
    end

    token = JsonWebToken.encode(user_id: user.id, name: user.name, email: user.email)
    { success: true, token: token }
  end

  def self.forgot_password(email)
    begin
      user = User.find_by(email: email)
      raise InvalidEmailError, "User with this email does not exist" if user.nil?
  
      @@otp = generate_otp
      UserMailer.text_mail(user.email, @@otp).deliver_now
  
      { success: true, message: "OTP sent successfully" }
    rescue InvalidEmailError => e
      { success: false, error: e.message }
    rescue StandardError => e
      { success: false, error: "Something went wrong: #{e.message}" }
    end
  end

  def self.reset_password(user_id, rp_params)
    raise InvalidOtpError, "OTP has not been generated" if @@otp.nil?

    if rp_params[:otp].to_i == @@otp
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