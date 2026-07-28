require "test_helper"

class ApplicationRecordTest < ActiveSupport::TestCase
  test "adapter_sql picks sqlite branch on sqlite adapter" do
    result = ApplicationRecord.adapter_sql(sqlite: "sqlite_query", postgres: "pg_query", for_adapter: "SQLite")

    assert_equal "sqlite_query", result
  end

  test "adapter_sql picks postgres branch on postgres adapter" do
    result = ApplicationRecord.adapter_sql(sqlite: "sqlite_query", postgres: "pg_query", for_adapter: "PostgreSQL")

    assert_equal "pg_query", result
  end
end
