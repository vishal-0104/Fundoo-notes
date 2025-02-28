class UserMailer < ApplicationMailer
  default from: "kanojiavishal0401@gmail.com"

  def forgot_password_email(email, otp)
    @otp = otp
    Rails.logger.info "📧 Sending OTP email to #{email}, please wait..."
    
    mail(to: email, subject: "Fundoo Notes - Reset Password OTP") do |format|
      format.text { render plain: "Your OTP for password reset is: #{@otp}. This OTP will expire in 1 minute." }
    end

    Rails.logger.info "✅ OTP email sent successfully to #{email}!"
  end
end
