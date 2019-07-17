# frozen_string_literal: true

class InviteeNotesController < ApplicationController
  before_action :set_invitee_note, only: [:show, :edit, :update, :destroy]

  # GET /invitee_notes
  # GET /invitee_notes.json
  def index
    @invitee_notes = InviteeNote.all
  end

  # GET /invitee_notes/1
  # GET /invitee_notes/1.json
  def show; end

  # GET /invitee_notes/new
  def new
    @invitee_note = InviteeNote.new
  end

  # GET /invitee_notes/1/edit
  def edit; end

  # POST /invitee_notes
  # POST /invitee_notes.json
  def create
    @invitee_note = InviteeNote.new(invitee_note_params)

    respond_to do |format|
      if @invitee_note.save
        format.html { redirect_to @invitee_note, notice: "Invitee note was successfully created." }
        format.json { render :show, status: :created, location: @invitee_note }
      else
        format.html { render :new }
        format.json { render json: @invitee_note.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /invitee_notes/1
  # PATCH/PUT /invitee_notes/1.json
  def update
    respond_to do |format|
      if @invitee_note.update(invitee_note_params)
        format.html { redirect_to @invitee_note, notice: "Invitee note was successfully updated." }
        format.json { render :show, status: :ok, location: @invitee_note }
      else
        format.html { render :edit }
        format.json { render json: @invitee_note.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /invitee_notes/1
  # DELETE /invitee_notes/1.json
  def destroy
    @invitee_note.destroy
    respond_to do |format|
      format.html { redirect_to invitee_notes_url, notice: "Invitee note was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_invitee_note
    @invitee_note = InviteeNote.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def invitee_note_params
    params.require(:invitee_note).permit(:invitee_id, :note, :source)
  end
end
