# frozen_string_literal: true

class Api::V1::SyncController < Api::V1::BaseController
  # POST /api/v1/sync
  def create
    sync_params = params.require(:sync).permit!

    if sync_params.blank?
      return render_success(nil, "No sync data provided")
    end

    result = SyncService.apply_sync(user: current_user, sync_params: sync_params)

    if result[:success]
      render_success(nil, "Sync completed successfully")
    else
      render_error(
        result[:errors],
        "Sync completed with errors",
        :unprocessable_content
      )
    end
  rescue StandardError => e
    Rails.logger.error("Sync error: #{e.message}\n#{e.backtrace.first(5).join("\n")}")
    render_error([e.message], "Sync failed", :internal_server_error)
  end
end
