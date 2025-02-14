require 'rails_helper'

RSpec.describe UsersService, type: :service do
  describe "#create_user" do
    context "when the user is created successfully" do
      it "returns a success response" do
        user_params = { email: "john1@example.com", password: "Password123@", name: "John Doe", mobile_number: "+91-7087077809"}
        result = UsersService.create_user(user_params)
        expect(result[:success]).to be(true)
        expect(result[:user]).to be_present
      end
    end

    context "when user creation fails" do
      it "returns errors if email is missing" do
        result = UsersService.create_user(name: "John Doe", password: "Password123@", mobile_number: "+919876543210")
      
        expect(result[:success]).to be(false)
        expect(result[:errors][:email]).to include("can't be blank")  # Fix error expectation
      end
    end
  end

  describe "#authenticate_user" do
  let!(:user) { User.create!(name: "John Doe", email: "john1@example.com", password: "Password123@", mobile_number: "+91-9876543210") }


    context "when login is successful" do
      it "returns a token" do
        login_params = { email: "john1@example.com", password: "Password123@" }
        result = UsersService.authenticate_user(login_params)
        expect(result[:success]).to be(true)
        expect(result[:token]).to be_present
      end
    end

    context "when email is invalid" do
      it "raises an InvalidEmailError" do
        login_params = { email: "wrong1@example.com", password: "Password123@" }
        expect { UsersService.authenticate_user(login_params) }.to raise_error(UsersService::InvalidEmailError, "Invalid email")
      end
    end

    context "when password is incorrect" do
      it "raises an InvalidPasswordError" do
        login_params = { email: "john1@example.com", password: "WrongPassword@" }
        expect { UsersService.authenticate_user(login_params) }.to raise_error(UsersService::InvalidPasswordError, "Invalid password")
      end
    end
  end

  describe "#forgot_password" do
  let!(:user) { User.create!(name: "John Doe", email: "john1@example.com", password: "Password123@", mobile_number: "+91-9876543210") }


    context "when the email exists" do
      it "sends an OTP via RabbitMQ" do
        expect(RabbitMQPublisher).to receive(:publish).with("email_queue", hash_including(email: "john1@example.com"))
        result = UsersService.forgot_password("john1@example.com")
        expect(result[:success]).to be(true)
        expect(result[:otp]).to be_present
      end
    end

    context "when the email does not exist" do
      it "returns an error message" do
        result = UsersService.forgot_password("wrong1@example.com")
        expect(result[:success]).to be(false)
        expect(result[:error]).to eq("User with this email does not exist")
      end
    end
  end

  describe "#reset_password" do
  let!(:user) { User.create!(name: "John Doe", email: "john1@example.com", password: "Password123@", mobile_number: "+91-9876543210") }


    before do
      UsersService.forgot_password("john1@example.com")
    end

    context "when OTP is valid" do
      it "resets the user's password" do
        otp = UsersService.class_variable_get(:@@otp)
        result = UsersService.reset_password(user.id, { otp: otp, new_password: "NewPassword123@" })
        expect(result[:success]).to be(true)
        user.reload
        expect(user.authenticate("NewPassword123@")).to be_truthy
      end
    end

    context "when OTP is invalid" do
      it "returns an error" do
        result = UsersService.reset_password(user.id, { otp: "wrongotp", new_password: "NewPassword123@" })
        expect(result[:success]).to be(false)
        expect(result[:errors]).to eq("Invalid OTP")
      end
    end
  end
end