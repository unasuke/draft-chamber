# frozen_string_literal: true

class SummariesController < ApplicationController
  def index
    @pagy, @summaries = pagy(current_user.summaries.linked.recent)
  end

  def destroy
    summary = deletable_summaries.find(params[:id])
    summary.destroy!

    redirect_to summaries_path, notice: "Summary deleted."
  end

  private

  def deletable_summaries
    current_user.admin? ? Summary.all : current_user.summaries
  end
end
