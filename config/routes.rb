Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post '/users', to: 'users#createUser'
      post 'users/login', to: 'users#login'
    end
  end
end
