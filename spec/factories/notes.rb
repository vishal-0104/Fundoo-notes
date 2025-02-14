FactoryBot.define do
  factory :note do
    title { "Sample Note" }
    content { "This is a test note." }
    is_deleted { false }
    is_archived { false }
    association :user
  end
end
