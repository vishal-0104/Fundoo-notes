require 'bunny'
require 'json'
require 'net/smtp'

class RabbitMQConsumer
  def self.start(queue_name = "notes_queue")
    connection = Bunny.new
    connection.start

    channel = connection.create_channel
    queue = channel.queue(queue_name, durable: true)

    puts "🟢 [RabbitMQ] Waiting for messages in #{queue_name}..."

    queue.subscribe(block: true) do |_delivery_info, _properties, body|
      message = JSON.parse(body)
      puts "📥 [RabbitMQ] Received message: #{message}"

      process_message(message)
    end

    connection.close
  end

  def self.process_message(message)
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
  
  def self.start(queue_name = "email_queue")
    connection = Bunny.new
    connection.start

    channel = connection.create_channel
    queue = channel.queue(queue_name, durable: true)

    puts "📥 [RabbitMQ] Waiting for messages in #{queue_name}..."

    queue.subscribe(block: true) do |_delivery_info, _properties, body|
      message = JSON.parse(body)
      puts "📩 [RabbitMQ] Received message: #{message}"

      process_message(message)
    end
  end

  def self.process_message(message)
    case message["event"]
    when "forgot_password"
      send_reset_password_email(message["email"], message["otp"])
    else
      puts "⚠️ Unknown event: #{message['event']}"
    end
  end

  def self.send_reset_password_email(email, otp)
    email_body = "Your OTP for password reset is: #{otp}. This OTP will expire in 1 minute."

    # Simulating email sending (replace with actual email service)
    puts "📧 Sending OTP email to #{email}: #{email_body}"
  end
end
