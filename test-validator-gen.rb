require 'sqlite3'
require 'yaml'
require 'uri'
require 'csv'
require 'dm-migrations'
require_relative './CapabilityStatement-datamapper'
require_relative './CapabilityStatement-db'
require_relative './checklist-db'
require_relative './parse-request'
require_relative './validator-search'
require_relative './datatypes-check'

class TestValidator

  def initialize(file_name = 'data.db')
    @db = SQLite3::Database.new(file_name)
  end

  def run_vaildation()
    opts = YAML.load_file(File.join(File.dirname(__FILE__), 'proxy.yml'))
    endpoint = URI::HTTP.build(host: opts[:Host], port: opts[:Port])

    # DataMapper.auto_migrate!
    DataMapper.auto_upgrade!

    include ValidSearch
    include CheckDatatypes
    Request.each do |req|
      re = ParseRequest.new(req, endpoint.to_s)
      re.update
      resource = re.req_resource
      request_type = re.req_method
      search_param = re.search_param
      present = re.present
      present_code = re.intCode
      request_id = req.request_id
      request_uri = req.request_uri
      res = Response.last request_id: req.request_id
      response_status = res.status

      search_valid = nil
      if re.search_param != nil
        search_valid = (response_status == "200") and valid_shall(re.req_resource, re.search_param)
        search_comb = combine_search(re.req_resource, re.search_param)

        req_params = re.instance_variable_get(:@req_params)
        param_type = []
        req_params.each do |k, v|
          sp = SearchParam.first type: re.req_resource, name: k
          if sp.nil?
            param_type.append(nil)
          else
            param_type.append(check_types(v, sp.stype))
          end
        end
      end

      CheckList.create resource: resource,
                       request_type: request_type,
                       search_param: search_param,
                       search_valid: search_valid,
                       search_combination: search_comb,
                       search_type: param_type,
                       present: present,
                       present_code: present_code,
                       request_id: request_id,
                       request_uri: request_uri,
                       response_status: response_status
    end

    # export to csv
    cnames = []
    CheckList.properties.to_a.each do |n|
      cnames.append(n.name.to_s)
    end

    puts("Generating report to checklist.csv")
    CSV.open("checklist.csv", "wb") do |csv|
      csv << cnames
      CheckList.each do |cl|
        values = []
        cnames.each do |n|
          values.append(cl[n])
        end
        csv << values
      end
    end

    end

end
