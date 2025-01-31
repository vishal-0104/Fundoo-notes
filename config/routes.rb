Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post '/users', to: 'users#create_user'
      post '/users/login', to: 'users#user_login'
      put '/users/forgot_password', to: 'users#forgot_password'
      put '/users/reset_password/:id', to: 'users#reset_password'
    end
  end
end