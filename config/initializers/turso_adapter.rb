# activerecord-libsql 0.1.x creates boolean/decimal/json columns as INTEGER/REAL/TEXT
# (so they read back as Integer/Float/String instead of true/false, BigDecimal and
# Array/Hash), returns column defaults still wrapped in SQL quotes ("'access'"), and
# doesn't implement #indexes.
# Use the sqlite3 adapter's column types and default parsing so a database behaves
# the same whether it's opened locally with sqlite3 or remotely through Turso.
require "active_record/connection_adapters/sqlite3_adapter"
require "active_record/connection_adapters/libsql_adapter"

module TursoAdapterFixes
  def native_database_types
    ActiveRecord::ConnectionAdapters::SQLite3Adapter::NATIVE_DATABASE_TYPES
  end

  def columns(table_name)
    internal_exec_query("PRAGMA table_info(#{quote_table_name(table_name)})", "SCHEMA").map do |row|
      ActiveRecord::ConnectionAdapters::Column.new(
        row["name"],
        extract_default(row["dflt_value"]),
        fetch_type_metadata(row["type"].to_s),
        row["notnull"].to_i.zero?
      )
    end
  end

  # Not implemented by the gem; uniqueness validations need it.
  def indexes(table_name)
    internal_exec_query("PRAGMA index_list(#{quote_table_name(table_name)})", "SCHEMA").filter_map do |row|
      next if row["origin"] == "pk" || row["name"].start_with?("sqlite_")

      columns = internal_exec_query("PRAGMA index_info(#{quote(row['name'])})", "SCHEMA").map { |col| col["name"] }
      ActiveRecord::ConnectionAdapters::IndexDefinition.new(table_name, row["name"], row["unique"].to_i == 1, columns)
    end
  end

  private

  def extract_default(default)
    case default
    when nil, /\Anull\z/i then nil
    when /\A'(.*)'\z/m then $1.gsub("''", "'")
    when /\A-?\d+(\.\d*)?\z/ then default
    end
  end
end

ActiveRecord::ConnectionAdapters::LibsqlAdapter.prepend(TursoAdapterFixes)

# The gem opens a new HTTPS connection (TCP + TLS handshake) for every query, which
# costs several hundred ms each. Reuse one keep-alive connection per adapter instead.
module TursoKeepAlive
  RETRYABLE_ERRORS = [ EOFError, Errno::ECONNRESET, Errno::EPIPE, OpenSSL::SSL::SSLError ].freeze

  private

  def hrana_pipeline(baton, requests)
    body = { "requests" => requests }
    body["baton"] = baton if baton
    uri = URI.parse(@hrana_url)

    request = Net::HTTP::Post.new(uri.path.empty? ? "/" : uri.path)
    request["Authorization"] = "Bearer #{@token}"
    request["Content-Type"] = "application/json"
    request.body = JSON.generate(body)

    attempts = 0
    begin
      attempts += 1
      response = turso_http(uri).request(request)
    rescue *RETRYABLE_ERRORS
      @turso_http&.finish rescue nil
      @turso_http = nil
      # A dropped idle connection is safe to retry outside a transaction; inside
      # one the server-side stream (baton) is gone, so let the error surface.
      retry if attempts == 1 && baton.nil?
      raise
    end

    raise "HTTP error #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError, Socket::ResolutionError => e
    raise "HTTP request failed: #{@hrana_url}: #{e.message}"
  end

  def turso_http(uri)
    @turso_http ||= Net::HTTP.new(uri.host, uri.port).tap do |http|
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 10
      http.read_timeout = 30
      http.keep_alive_timeout = 15
    end
    @turso_http.start unless @turso_http.started?
    @turso_http
  end
end

TursoLibsql::Connection.prepend(TursoKeepAlive)
