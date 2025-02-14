require 'rails_helper'
require 'redis'
require_relative '../../app/services/notes_service'
require_relative '../../app/services/rabbitmq_publisher'

RSpec.describe NotesService do
  let(:user) { create(:user) } # Assuming FactoryBot is used
  let(:note) { create(:note, user: user) }
  let(:valid_params) { { title: "Test Note", content: "This is a test note." } }
  let(:redis_mock) { instance_double(Redis, get: nil, set: nil, del: nil) }
  let(:service) { NotesService.new(user, redis_mock) }


  before do
    allow(Redis).to receive(:new).and_return(redis_mock)
    allow(redis_mock).to receive(:del)
    allow(redis_mock).to receive(:del) { |key| puts "Redis DEL called with key: #{key}" }
    
    allow(redis_mock).to receive(:get).with(any_args) do |key|
      puts "Redis GET called with key: #{key}"
      nil
    end
  
    allow(redis_mock).to receive(:set).with(any_args) do |key, _|
      puts "Redis SET called with key: #{key}"
      "OK"
    end
  
    allow(redis_mock).to receive(:del).with(any_args) do |key|
      puts "Redis DEL called with key: #{key}"
      1
    end
  
    allow(RabbitMQPublisher).to receive(:publish).and_return(true)
  end
  

  describe "#list_notes" do
    it "fetches notes from database if not in Redis" do
      service = NotesService.new(user, {})
      allow(user.notes).to receive(:where).and_return([note])

      result = service.list_notes

      expect(result).to be_an(Array)
      expect(result.first["title"]).to eq(note.title)
      expect(redis_mock).to have_received(:set).with("user_#{user.id}_notes", anything)
      expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", { event: "list_notes", user_id: user.id })
    end
  end

  describe "#create_note" do
    it "creates a new note and clears Redis cache" do
      service = NotesService.new(user, valid_params)

      result = service.create_note

      expect(result[:success]).to be(true)
      expect(result[:note]).to be_present
      expect(redis_mock).to have_received(:del).with("user_#{user.id}_notes")
      expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", hash_including(event: "create_note"))
    end
  end

  describe "#update_note" do
    it "updates an existing note and clears Redis cache" do
      service = NotesService.new(user, { title: "Updated Title" })

      result = service.update_note(note)

      expect(result[:success]).to be(true)
      expect(note.reload.title).to eq("Updated Title")
      expect(redis_mock).to have_received(:del).with("user_#{user.id}_notes")
      expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", hash_including(event: "update_note"))
    end
  end

  describe "#soft_delete" do
    it "soft deletes a note and clears Redis cache" do
      service = NotesService.new(user, {})

      result = service.soft_delete(note)

      expect(result[:success]).to be(true)
      expect(note.reload.is_deleted).to be(true)
      expect(redis_mock).to have_received(:del).with("user_#{user.id}_notes")
      expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", hash_including(event: "soft_delete"))
    end
  end

  describe "#archive" do
    it "updates archive status of a note" do
      service = NotesService.new(user, { is_archived: true })

      result = service.archive(note)

      expect(result[:success]).to be(true)
      expect(note.reload.is_archived).to be(true)
      expect(redis_mock).to have_received(:del).with("user_#{user.id}_notes")
      expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", hash_including(event: "archive"))
    end
  end

  describe "#change_color" do
    it "updates note color" do
      service = NotesService.new(user, { color: "blue" })

      result = service.change_color(note)

      expect(result[:success]).to be(true)
      expect(note.reload.color).to eq("blue")
      expect(redis_mock).to have_received(:del).with("user_#{user.id}_notes")
      expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", hash_including(event: "change_color"))
    end
  end

  describe "#add_collaborator" do
    let(:collaborator) { create(:user, email: "collab@example.com") }

    context "when the collaborator exists" do
      it "adds a collaborator to the note" do
        service = NotesService.new(user, { email: collaborator.email })

        result = service.add_collaborator(note)

        expect(result[:success]).to be(true)
        expect(note.collaborators).to include(collaborator)
        expect(RabbitMQPublisher).to have_received(:publish).with("notes_queue", hash_including(event: "add_collaborator"))
      end
    end

    context "when the email is missing" do
      it "returns an error" do
        service = NotesService.new(user, {})

        result = service.add_collaborator(note)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq("Email is required")
      end
    end

    context "when the collaborator does not exist" do
      it "returns an error" do
        service = NotesService.new(user, { email: "nonexistent@example.com" })

        result = service.add_collaborator(note)

        expect(result[:success]).to be(false)
        expect(result[:error]).to eq("User not found")
      end
    end
  end
end
