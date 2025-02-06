Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      post '/users', to: 'users#create_user'
      post '/users/login', to: 'users#user_login'
      put '/users/forgot_password', to: 'users#forgot_password'
      put '/users/reset_password/:id', to: 'users#reset_password'
      resources :notes do
        member do
          put :archive
          put :change_color
          post :add_collaborator
          delete :remove_collaborator
          patch :soft_delete
        end
      end
    end
  end
end