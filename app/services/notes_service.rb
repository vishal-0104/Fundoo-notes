require_relative 'rabbitmq_publisher'

class NotesService
  @@redis = Redis.new(host: "localhost", port: 6379)
  def initialize(user, params)
    @user = user
    @params = params
  end

  def list_notes
    cache_key = "user_#{@user.id}_notes"
  
    begin
      notes = @@redis.get(cache_key)
      puts "Redis Fetch: #{notes.nil? ? 'MISS' : 'HIT'}"
  
      if notes.nil?
        notes = @user.notes.where(is_deleted: false).to_json
        @@redis.set(cache_key, notes, ex: 60.minutes.to_i) # Cache for 1 hour
        puts "Data stored in Redis"
      else
        puts "Data retrieved from Redis"
      end
  
      RabbitMQPublisher.publish("notes_queue", { event: "list_notes", user_id: @user.id })
      JSON.parse(notes) # Return parsed JSON data
    rescue => e
      puts "Redis Error: #{e.message}"
      @user.notes.where(is_deleted: false) # Fallback to database
    end
  end
  
  
  

  def create_note
    note = @user.notes.build(@params)
    if note.save
      @@redis.del("user_#{@user.id}_notes") # Clear cache
      RabbitMQPublisher.publish("notes_queue", { event: "create_note", note_id: note.id, user_id: @user.id })
      { success: true, note: note }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end
  

  def update_note(note)
    if note.update(@params)
      @@redis.del("user_#{@user.id}_notes") # Clear cache
      RabbitMQPublisher.publish("notes_queue", { event: "update_note", note_id: note.id, user_id: @user.id })
      { success: true, note: note }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end
  
  def soft_delete(note)
    if note.update(is_deleted: true)
      @@redis.del("user_#{@user.id}_notes") # Clear cache
      RabbitMQPublisher.publish("notes_queue", { event: "soft_delete", note_id: note.id, user_id: @user.id })
      { success: true, message: 'Note soft deleted successfully' }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end
  

  def archive(note)
    if note.update(is_archived: @params[:is_archived])
      RabbitMQPublisher.publish("notes_queue", { event: "archive", note_id: note.id, user_id: @user.id })
      { success: true, message: 'Note archived status updated successfully', note: note }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end

  def change_color(note)
    if note.update(color: @params[:color])
      RabbitMQPublisher.publish("notes_queue", { event: "change_color", note_id: note.id, user_id: @user.id })
      { success: true, message: 'Note color updated' }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end

  def add_collaborator(note)
    email = @params[:email]
    return { success: false, error: 'Email is required' } unless email

    user = User.find_by(email: email)
    return { success: false, error: 'User not found' } unless user
    return { success: false, error: 'User is already a collaborator' } if note.collaborators.include?(user)

    note.collaborators << user
    RabbitMQPublisher.publish("notes_queue", { event: "add_collaborator", note_id: note.id, collaborator_id: user.id })
    { success: true, message: 'Collaborator added successfully', note: note }
  end
end
