module Api
  module V1 
    class UsersController < ApplicationController
      skip_before_action :verify_authenticity_token

      def createUser
        result = UsersService.create_user(user_params)

        if result[:success]
          render json: result[:user], status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def login
        result = UsersService.authenticate_user(login_params)

        if result[:success]
          render json: { message: "Login successful", token: result[:token] }, status: :ok
        else
          render json: { errors: result[:errors] }, status: :unauthorized
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :mobile_number)
      end

      def login_params
        params.require(:user).permit(:email, :password)
      end
    end
  end
end