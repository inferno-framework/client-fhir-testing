require 'sqlite3'

class FHIRTransactionDB
  def initialize(file_name = 'data.db')
    @db = SQLite3::Database.new(file_name)
    @db.execute("DROP TABLE IF EXISTS requests")
    @db.execute("DROP TABLE IF EXISTS responses")
    sql = %{
      CREATE TABLE IF NOT EXISTS requests (
        request_id INTEGER PRIMARY KEY,
        request_method TEXT NOT NULL,
        request_uri TEXT NOT NULL,
        remote_addr TEXT NOT NULL,
        user_agent TEXT NOT NULL,
        headers TEXT NOT NULL,
        timestamp DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
        data TEXT
      );
    }
    @db.execute(sql)
    sql = %{
      CREATE TABLE IF NOT EXISTS responses (
        response_id INTEGER PRIMARY KEY,
        request_id INTEGER NOT NULL,
        status TEXT NOT NULL,
        headers TEXT NOT NULL,
        timestamp DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
        data TEXT
      );
    }
    @db.execute(sql)
    sql = %{
      CREATE TABLE IF NOT EXISTS sessions (
        session_id INTEGER PRIMARY KEY,
        first_request_id INTEGER NOT NULL,
        last_request_id INTEGER NOT NULL,
        dt DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW'))
      );
    }
    ret = @db.execute(sql)
    result = ret
  end

  def insert_request(headers, data, backend)
    request_method = headers['REQUEST_METHOD']
    request_uri = headers['REQUEST_URI']
    remote_addr = headers['REMOTE_ADDR']
    user_agent = headers['HTTP_USER_AGENT']
    # https://regexr.com/
    # match after the first slash + word after the domain name
    # need to pull out the backend first
    # like 'Patient'
    str_to_rm = URI(backend).path.chomp('/')
    removed_backend = headers['REQUEST_URI'].sub(/#{Regexp.escape(str_to_rm)}/, '')
    m = removed_backend.match(%r{^/([^/\?]+)/*.*$})
    sql = %{
      INSERT INTO requests
      (request_method, request_uri, remote_addr, user_agent, headers, data)
      VALUES
      (?, ?, ?, ?, ?, ?);
    }
    ins = @db.prepare(sql)
    ins.execute(request_method, request_uri, remote_addr,
                user_agent, headers.to_json, data.to_s)
    return @db.last_insert_row_id
  end

  def insert_response(request_id, status, headers, data)
    sql = %{
      INSERT INTO responses
      (request_id, status, headers, data)
      VALUES
      (?, ?, ?, ?);
    }
    ins = @db.prepare(sql)
    ins.execute(request_id, status, headers.to_json, data.to_s)
    return @db.last_insert_row_id
  end

end