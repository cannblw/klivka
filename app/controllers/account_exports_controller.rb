class AccountExportsController < ApplicationController
  def show
    generated_at = Time.current
    export = AccountExportSerializer.new(user: Current.user, generated_at:).as_json

    response.headers["Cache-Control"] = "no-store"
    send_data JSON.pretty_generate(export),
      filename: "klivka-export-#{generated_at.utc.strftime('%Y%m%dT%H%M%SZ')}.json",
      type: "application/json",
      disposition: "attachment"
  end
end
