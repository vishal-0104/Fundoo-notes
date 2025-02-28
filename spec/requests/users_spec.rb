require 'rails_helper'

RSpec.describe "Users API", type: :request do
  let(:valid_user_params) do
    {
      user: {
        email: "john1@example.com",
        password: "Password123@",
        name: "John Doe",
        mobile_number: "+91-7087077809"
      }
    }
  end

  let(:login_params) do
    {
      user: {
        email: "john1@example.com",
        password: "Password123@"
      }
    }
  end

  describe "POST /api/v1/users" do
    context "when the user is created successfully" do
      it "returns a success response with user data" do
        post "/api/v1/users", params: valid_user_params

        expect(response).to have_http_status(:created)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be(true)
        expect(json_response["user"]["email"]).to eq("john1@example.com")
      end
    end
  end

  describe "POST /api/v1/users/login" do
    before do
      post "/api/v1/users", params: valid_user_params # Create user first
    end

    context "when login is successful" do
      it "returns a JWT token" do
        post "/api/v1/users/login", params: login_params

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be(true)
        expect(json_response["token"]).to be_present
      end
    end

    context "when login fails" do
      it "returns an error for invalid email" do
        post "/api/v1/users/login", params: { user: { email: "wrong@example.com", password: "wrongpass" } }

        expect(response).to have_http_status(:bad_request)
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be(false)
        expect(json_response["error"]).to eq("Invalid email")
      end
    end
  end
end
