FactoryBot.define do
  factory :user do
    name { "Test User" }
    sequence(:email) { |n| "test#{n}@example.com" } # Ensure unique emails
    password { "Password@123" }
    sequence(:mobile_number) { |n| "+91-123456789#{n % 10}" } # Ensure unique mobile numbers
  end
end