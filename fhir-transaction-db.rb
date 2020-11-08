require 'sqlite3'

class FHIRTransactionDB
  def initialize(file_name = 'data.db')
    @db = SQLite3::Database.new(file_name)
    sql = %{
      CREATE TABLE IF NOT EXISTS requests (
        request_id INTEGER PRIMARY KEY,
        method TEXT NOT NULL,
        request TEXT NOT NULL,
        headers TEXT NOT NULL,
        dt DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
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
        dt DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
        data TEXT
      );
    }
    @db.execute(sql)
  end

  def insert_request(method, request, headers, data)
    sql = %{
      INSERT INTO requests
      (method, request, headers, data)
      VALUES
      (?, ?, ?, ?);
    }
    ins = @db.prepare(sql)
    ins.execute(method, request, headers, data)
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
    ins.execute(request_id, status, headers, data)
    return @db.last_insert_row_id
  end

end
