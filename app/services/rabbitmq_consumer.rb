require 'bunny'
require 'json'
require 'net/smtp'

class RabbitMQConsumer
  def self.start
    connection = Bunny.new
    connection.start
    channel = connection.create_channel

    # Listen to Notes Queue
    notes_queue = channel.queue("notes_queue", durable: true)
    puts "🟢 [RabbitMQ] Waiting for messages in notes_queue..."
    notes_queue.subscribe(block: false, manual_ack: true) do |delivery_info, _properties, body|
      message = JSON.parse(body)
      process_notes_message(message)
      channel.ack(delivery_info.delivery_tag)
    end

    # Listen to Email Queue
    email_queue = channel.queue("email_queue", durable: true)
    puts "📥 [RabbitMQ] Waiting for messages in email_queue..."
    email_queue.subscribe(block: true, manual_ack: true) do |delivery_info, _properties, body|
      message = JSON.parse(body)
      process_email_message(message)
      channel.ack(delivery_info.delivery_tag)
    end
  end

  def self.process_notes_message(message)
    case message["event"]
    when "create_note"
      puts "📝 New note created with ID #{message['note_id']} by User #{message['user_id']}"
    when "update_note"
      puts "✏️ Note #{message['note_id']} updated by User #{message['user_id']}"
    when "soft_delete"
      puts "🗑️ Note #{message['note_id']} was soft deleted by User #{message['user_id']}"
    when "archive"
      puts "📦 Note #{message['note_id']} archive status updated by User #{message['user_id']}"
    when "change_color"
      puts "🎨 Note #{message['note_id']} color changed by User #{message['user_id']}"
    when "add_collaborator"
      puts "🤝 User #{message['collaborator_id']} added as collaborator to Note #{message['note_id']}"
    else
      puts "⚠️ Unknown event: #{message['event']}"
    end
  end

  def self.process_email_message(message)
    case message["event"]
    when "forgot_password"
      send_reset_password_email(message["email"], message["otp"])
    else
      puts "⚠️ Unknown event: #{message['event']}"
    end
  end

  def self.send_reset_password_email(email, otp)
    email_body = "Your OTP for password reset is: #{otp}. This OTP will expire in 1 minute."

    begin
      UserMailer.forgot_password_email(email, otp).deliver_now
      puts "📧 OTP email successfully sent to #{email}"
    rescue StandardError => e
      puts "❌ Error sending email: #{e.message}"
    end
  end
end
