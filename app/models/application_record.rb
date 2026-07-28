class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  def self.adapter_sql(sqlite:, postgres:, for_adapter: connection.adapter_name)
    if for_adapter.downcase.include?("sqlite")
      sqlite
    else
      postgres
    end
  end
end
