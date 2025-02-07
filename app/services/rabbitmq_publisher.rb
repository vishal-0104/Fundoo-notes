require 'bunny'
require 'json'

class RabbitMQPublisher
  def self.publish(queue_name, message)
    connection = Bunny.new
    connection.start

    channel = connection.create_channel
    queue = channel.queue(queue_name, durable: true)  # Ensure queue is durable

    message_body = message.to_json
    queue.publish(message_body, persistent: true)  # Make message persistent

    puts "📨 [RabbitMQ] Message sent to #{queue_name}: #{message_body}"  # Debug log

    connection.close
  end

  # def self.publish(queue_name, message)
  #   connection = Bunny.new
  #   connection.start
  
  #   channel = connection.create_channel
  #   queue = channel.queue(queue_name, durable: true)
  
  #   message_body = message.to_json
  #   queue.publish(message_body, persistent: true)
  
  #   puts "📨 [RabbitMQ] Message sent to #{queue_name}: #{message_body}"  # Debugging log
  
  #   connection.close
  # end
  
end
