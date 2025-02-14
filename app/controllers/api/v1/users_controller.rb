module Api
  module V1 
    class UsersController < ApplicationController
      skip_before_action :authenticate_user!, only: [:create_user, :user_login, :forgot_password, :reset_password]

      def create_user
        result = UsersService.create_user(user_params)

        if result[:success]
          render json: { success: true, user: result[:user] }, status: :created
        else
          render json: { success: false, errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def user_login
        begin
          result = UsersService.authenticate_user(login_params)
          render json: { success: true, message: "Login successful", token: result[:token] }, status: :ok
        rescue UsersService::InvalidEmailError, UsersService::InvalidPasswordError => e
          render json: { success: false, error: e.message }, status: :bad_request
        end
      end

      def forgot_password
        result = UsersService.forgot_password(forgot_password_params[:email])
        if result[:success]
          render json: { success: true, message: result[:message], otp: result[:otp] }, status: :ok
        else
          render json: { success: false, error: result[:error] }, status: :bad_request
        end
      end

      def reset_password
        user_id = params[:id]  
        result = UsersService.reset_password(user_id, reset_password_params)

        if result[:success]
          render json: { success: true, message: "Password updated successfully" }, status: :ok
        else
          render json: { success: false, errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :mobile_number)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end

      def forgot_password_params
        params.require(:user).permit(:email)  
      end

      def reset_password_params
        params.require(:user).permit(:new_password, :otp)
      end
    end
  end
end
