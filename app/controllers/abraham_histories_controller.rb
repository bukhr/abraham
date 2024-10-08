# frozen_string_literal: true

class AbrahamHistoriesController < ApplicationController
  load_and_authorize_resource

  def create
    @abraham_history = AbrahamHistory.new(abraham_history_params)
    @abraham_history.creator_id = current_user.id
    respond_to do |format|
      if @abraham_history.save
        format.json { render json: @abraham_history, status: :created }
      else
        format.json { render json: @abraham_history.errors, status: :unprocessable_entity }
      end
    end
  end

  private

    def abraham_history_params
      params.require(:abraham_history).permit(:controller_name, :action_name, :tour_name)
    end
end
