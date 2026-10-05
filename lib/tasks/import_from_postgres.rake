# Copies every row from the old Postgres database into the database the app is
# currently configured for (local SQLite, or Turso when TURSO_DATABASE_URL is set).
# IDs and timestamps are preserved; validations and callbacks are skipped.
#
#   POSTGRES_DATABASE_URL=postgres://... bin/rails db:import_from_postgres
#   REPLACE=1 ...  # wipe the destination tables first instead of refusing
#
# The destination schema must already be loaded (bin/rails db:schema:load).
namespace :db do
  desc "Copy all data from POSTGRES_DATABASE_URL into the current database"
  task import_from_postgres: :environment do
    require "pg"

    # Parents before children so foreign keys resolve.
    tables = %w[
      users waitlists auth_codes tokens custom_fields clients
      client_custom_field_values orders folders galleries
    ]
    batch_size = Integer(ENV.fetch("BATCH_SIZE", 200))

    source_url = ENV["POSTGRES_DATABASE_URL"].presence or abort "Set POSTGRES_DATABASE_URL to the Postgres database to copy from."

    source_base = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
      def self.name = "PostgresImportSource"
    end
    source_base.establish_connection(source_url)

    model_for = lambda do |base, table|
      Class.new(base) do
        self.table_name = table
        self.inheritance_column = nil
        define_singleton_method(:name) { "#{base.name}::#{table.classify}" }
      end
    end

    dest_models = tables.to_h { |t| [ t, model_for.call(ActiveRecord::Base, t) ] }
    source_models = tables.to_h { |t| [ t, model_for.call(source_base, t) ] }

    puts "Source:      #{source_base.connection_db_config.host}/#{source_base.connection_db_config.database}"
    puts "Destination: #{ActiveRecord::Base.connection.adapter_name} #{ActiveRecord::Base.connection_db_config.database}"

    existing = tables.select { |t| dest_models[t].exists? }
    if existing.any?
      abort "Destination already has rows in: #{existing.join(', ')}. Re-run with REPLACE=1 to wipe them first." unless ENV["REPLACE"] == "1"

      tables.reverse_each { |t| dest_models[t].delete_all }
      puts "Wiped destination tables."
    end

    tables.each do |table|
      src = source_models[table]
      dest = dest_models[table]
      json_columns = dest.columns.select { |c| c.type == :json }.map(&:name)
      shared_columns = src.column_names & dest.column_names

      src.in_batches(of: batch_size) do |batch|
        rows = batch.map do |record|
          row = shared_columns.to_h { |c| [ c, record[c] ] }
          json_columns.each { |c| row[c] ||= [] if row.key?(c) }
          row
        end
        dest.insert_all!(rows, record_timestamps: false)
      end

      source_count = src.count
      dest_count = dest.count
      status = source_count == dest_count ? "ok" : "MISMATCH"
      puts format("  %-28s %6d -> %6d  %s", table, source_count, dest_count, status)
    end
  end
end
