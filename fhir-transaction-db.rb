require 'sqlite3'

class FHIRTransactionDB
  def initialize(file_name = 'data.db')
    @db = SQLite3::Database.new(file_name)
    sql = %{
      CREATE TABLE IF NOT EXISTS requests (
        request_id INTEGER PRIMARY KEY,
        method TEXT NOT NULL,
        request TEXT NOT NULL,
        dt DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
        data TEXT NOT NULL
      );
    }
    @db.execute(sql)
    sql = %{
      CREATE TABLE IF NOT EXISTS responses (
        response_id INTEGER PRIMARY KEY,
        request_id INTEGER NOT NULL,
        dt DATETIME default (STRFTIME('%Y-%m-%d %H:%M:%f', 'NOW')),
        data TEXT NOT NULL
      );
    }
    @db.execute(sql)
  end

  def insert_request(method, request, data)
    sql = %{
      INSERT INTO requests
      (method, request, data)
      VALUES
      (?, ?, ?);
    }
    ins = @db.prepare(sql)
    ins.execute(method, request, data)
    return @db.last_insert_row_id
  end

  def insert_response(request_id, data)
    sql = %{
      INSERT INTO responses
      (request_id, data)
      VALUES
      (?, ?);
    }
    ins = @db.prepare(sql)
    ins.execute(request_id, data)
    return @db.last_insert_row_id
  end

end
