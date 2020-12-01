require 'json'
require 'csv'
require 'sqlite3'
require 'dm-core'
require 'yaml'

class ReportGen
  def initialize(file_name = 'data.db')
    @db = SQLite3::Database.new(file_name)
    @db.results_as_hash = true

  end

  def getSearchCategories()
    stmtc = @db.prepare ("SELECT * FROM search_criteria")
    rst = stmtc.execute
    return rst
  rescue SQLite3::Exception => e

    puts "Exception occurred"
    puts e
  end

  def getCountSessionID()
    stm = @db.prepare ("SELECT count(request_id) as count FROM requests")
    rs = stm.execute
    resultSet = rs.next
    puts resultSet
  rescue SQLite3::Exception => e

    puts "Exception occurred"
    puts e

  ensure
    stm.close if stm

    ret = resultSet['count']
    puts ret
    return ret
  end

  def insertSession(start_id,last_id,dt)
    sql = %{
      INSERT INTO sessions
      (first_request_id, last_request_id, dt)
      VALUES
      (?, ?, ?);
    }
    ins = @db.prepare(sql)
    ins.execute(start_id, last_id, dt)
  end

  def generateReport()
    #todo: need to be able to populate data into check_lists table here.
    #eval File.read("test-generator.rb")
    # pid=Process.fork do
    #   require './test-generator.rb'
    #   Process.exit
    # end
    # ignored, status = Process.waitpid2(pid, Process::WNOHANG)
    # puts "script.rb PID #{pid} exited, exit status: #{status.exitstatus}"

    stm = @db.prepare ("SELECT first_request_id, last_request_id ,dt FROM sessions ORDER BY session_id ASC")
    rs = stm.execute
    rec_hash = Hash.new
    rec_hash[:res] = []
    while (resultSet = rs.next) do
      res_hash = Hash.new
      res_hash[:start] =resultSet['first_request_id']
      res_hash[:last] =resultSet['last_request_id']
      res_hash[:dt] =resultSet['dt']
      puts resultSet
      rec_hash[:res] << res_hash
    end

    retArray = Array.new
    rec_hash[:res].each { |item|
      puts item
      retArray << buildSearchJson(item[:start],item[:last], item[:dt])
    }
    retData = retArray.join(',')
    retData = "[" + retData + "]"
    puts retData

    rescue SQLite3::Exception => e

      puts "Exception occurred"
      puts e

    ensure
      stm.close if stm

      #@db.close if @db

      return retData
  end


  def buildSearchJson(start, last, dt)
    s_hash = Hash.new
    s_hash[:Session]=dt
    s_hash[:Records] =[]

    rstCategories = getSearchCategories()

    while (i = rstCategories.next) do
      i_hash = Hash.new
      i_hash[:Interaction]="search-type"
      i_hash[:Resource]=i['res_type']
      i_hash[:TestResult]=[]

      stmRepo = @db.prepare ("SELECT * FROM check_lists WHERE request_id >= ? and request_id <= ? and resource = ? and request_type = ? ")
      stmRepo.bind_params start, last, i['res_type'], 'search-type'
      rst = stmRepo.execute
      cnt =0
      while (resultSet2 = rst.next) do
        cnt = cnt + 1
        r_hash = Hash.new

        r_hash[:search_param]=resultSet2['search_param']
        r_hash[:present_code]=resultSet2['present_code']
        r_hash[:request_id]=resultSet2['request_id']
        r_hash[:response_status]=resultSet2['response_status']
        r_hash[:search_valid]=resultSet2['search_valid']
        i_hash[:TestResult]<< r_hash
        puts resultSet2
      end
      if cnt < 1
        r_hash = Hash.new
        r_hash[:no_match_found]="No search transaction found during recording sesion."
        i_hash[:TestResult]<< r_hash
      end
      s_hash[:Records]<<i_hash

    end
    puts JSON.generate(s_hash)
    returnJson = JSON.generate(s_hash)


  rescue SQLite3::Exception => e

    puts "Exception occurred"
    puts e

  ensure
    stmRepo.close if stmRepo


    returnJson
  end

end





