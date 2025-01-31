module Api
  module V1 
    class UsersController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create_user
        result = UsersService.create_user(user_params)

        if result[:success]
          render json: result[:user], status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def user_login

        begin
          result = UsersService.authenticate_user(login_params)
          render json: { message: "Login successful", token: result[:token] }, status: :ok
        rescue UsersService::InvalidEmailError, UsersService::InvalidPasswordError => e
          render json: { error: e.message }, status: :bad_request
        end

        # begin 
        #   result = UsersService.authenticate_user(login_params)

        #   if result[:success]
        #     render json: { message: "Login successful", token: result[:token] }, status: :ok
        #   else
        #     render json: { errors: result[:errors] }, status: :unauthorized
        #   end
        # rescue UsersService::InvalidEmailError => e
        #   render json: { error: e.message }, status: :bad_request
        # end
      end

      def forgot_password
        result = UsersService.forgot_password(forgot_password_params[:email])
        if result[:success]
          render json: { message: result[:message], otp: result[:otp] }, status: :ok
        else
          render json: { error: result[:error] }, status: :bad_request
        end
      end

      def reset_password
        user_id = params[:id]  # Extracting user ID from request params
        result = UsersService.reset_password(user_id, reset_password_params)

        if result[:success]
          render json: { message: "Password updated successfully" }, status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
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