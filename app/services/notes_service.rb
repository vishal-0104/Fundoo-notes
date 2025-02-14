require_relative 'rabbitmq_publisher'

class NotesService
  @@redis = Redis.new(host: "localhost", port: 6379)
  def initialize(user, params)
    @user = user
    @params = params
    @@redis = Redis.new
  end

  def list_notes
    cache_key = "user_#{@user.id}_notes"
    cached_data = @@redis.get(cache_key)

    if cached_data
      JSON.parse(cached_data)
    else
      notes = @user.notes.where(is_deleted: false).as_json
      @@redis.set(cache_key, notes.to_json)
      RabbitMQPublisher.publish("notes_queue", { event: "list_notes", user_id: @user.id })
      notes
    end
  end
  
  
  

  
  def create_note
    note = @user.notes.create(@params)
    if note.persisted?
      @@redis.del("user_#{@user.id}_notes") # Ensure Redis cache is cleared
      RabbitMQPublisher.publish("notes_queue", { event: "create_note", note_id: note.id })
      { success: true, note: note }
    else
      { success: false, error: note.errors.full_messages }
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
      @@redis.del("user_#{@user.id}_notes") # Ensure cache is cleared
      RabbitMQPublisher.publish("notes_queue", { event: "archive", note_id: note.id, user_id: @user.id })
      { success: true, message: 'Note archived status updated successfully', note: note }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end
  

  def change_color(note)
    if note.update(color: @params[:color])
      @@redis.del("user_#{@user.id}_notes") # Ensure cache is cleared
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
