class AddOtpToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp, :integer
    add_column :users, :otp_sent_at, :datetime
  end
end
