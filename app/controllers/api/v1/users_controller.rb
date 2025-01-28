module Api
  module V1 
    class UsersController < ApplicationController
      skip_before_action :verify_authenticity_token

      def createUser
        user = User.new(user_params)

        if user.save
          render json: user , status: :created
        else
          render json: {errors: user.errors}, status: :unprocessable_entity
        end
      end

      private

      def user_params
        params.require(:user).permit(:name, :email, :password, :mobile_number)
      end
    end
  end
end
