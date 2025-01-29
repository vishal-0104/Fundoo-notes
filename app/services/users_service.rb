class UsersService
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
    if user && user.authenticate(params[:password])
      token = JsonWebToken.encode(user_id: user.id, name: user.name, email: user.email)
      { success: true, token: token }
    else
      { success: false, errors: "Invalid email or password" }
    end
  end
end