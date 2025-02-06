class Note < ApplicationRecord
  has_and_belongs_to_many :users
  belongs_to :user
  has_many :collaborators, dependent: :destroy
  has_many :collaborator_users, through: :collaborators, source: :user
  has_and_belongs_to_many :collaborators, class_name: "User", join_table: "notes_users"
end
