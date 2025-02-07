require_relative 'rabbitmq_publisher'

class NotesService
  def initialize(user, params)
    @user = user
    @params = params
  end

  def list_notes
    notes = @user.notes.where(is_deleted: false)
    RabbitMQPublisher.publish("notes_queue", { event: "list_notes", user_id: @user.id })
    notes
  end

  def create_note
    note = @user.notes.build(@params)
    if note.save
      RabbitMQPublisher.publish("notes_queue", { event: "create_note", note_id: note.id, user_id: @user.id })
      { success: true, note: note }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end

  def update_note(note)
    if note.update(@params)
      RabbitMQPublisher.publish("notes_queue", { event: "update_note", note_id: note.id, user_id: @user.id })
      { success: true, note: note }
    else
      { success: false, errors: note.errors.full_messages }
    end
  end

  def soft_delete(note)
    if note.update(is_deleted: true)
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
