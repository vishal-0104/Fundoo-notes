module Api
  module V1
    class NotesController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user
      before_action :find_note, only: [:show, :update, :destroy, :change_color, :archive, :soft_delete]

      def index
        notes = NotesService.new(current_user, params).list_notes
        render json: notes, status: :ok
      end

      def create
        service = NotesService.new(current_user, note_params)
        result = service.create_note
        if result[:success]
          render json: result[:note], status: :created
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def show
        render json: @note, status: :ok
      end

      def update
        service = NotesService.new(current_user, note_params)
        result = service.update_note(@note)
        if result[:success]
          render json: result[:note], status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def destroy
        service = NotesService.new(current_user, params)
        result = service.soft_delete(@note)
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def archive
        service = NotesService.new(current_user, params[:note])
        result = service.archive(@note)
        if result[:success]
          render json: { message: result[:message], note: result[:note] }, status: :ok
        else
          render json: { error: result[:errors] }, status: :unprocessable_entity
        end
      end

      def change_color
        service = NotesService.new(current_user, params)
        result = service.change_color(@note)
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end

      def add_collaborator
        service = NotesService.new(current_user, params[:note])
        result = service.add_collaborator(@note)
        if result[:success]
          render json: { message: result[:message], note: result[:note] }, status: :ok
        else
          render json: { error: result[:error] }, status: :unprocessable_entity
        end
      end

      def soft_delete
        result = NotesService.new(current_user, params).soft_delete(@note)
      
        if result[:success]
          render json: { message: result[:message] }, status: :ok
        else
          render json: { errors: result[:errors] }, status: :unprocessable_entity
        end
      end
      

      private

      def note_params
        params.require(:note).permit(:title, :content, :color, :is_deleted, :is_archived, :email)
      end

      def find_note
        @note = Note.find_by(id: params[:id])
        if @note.nil?
          render json: { error: "Note not found" }, status: :not_found
          return
        end
        if @note.user_id != current_user.id
          render json: { error: "You do not have permission to modify this note" }, status: :forbidden
        end
      end

      def authenticate_user
        header = request.headers['Authorization']
        token = header.split(' ').last if header
        decoded = JsonWebToken.decode(token)
        @current_user = User.find_by(id: decoded[:user_id]) if decoded
        render json: { error: 'Unauthorized' }, status: :unauthorized unless @current_user
      end

      def current_user
        @current_user
      end
    end
  end
end
