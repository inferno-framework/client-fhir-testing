require 'yaml'
require 'uri'
require 'csv'
require_relative 'CapabilityStatement-datamapper'
require_relative 'CapabilityStatement-db'
require_relative 'checklist-db'
require_relative 'parse-request'
require 'dm-migrations'

opts = YAML.load_file('proxy.yml')
endpoint = URI::HTTP.build(host: opts[:Host], port: opts[:Port])

# DataMapper.auto_migrate!
DataMapper.auto_upgrade!

Request.each do |req|
  re = ParseRequest.new(req, endpoint.to_s)
  re.update
  resource = re.req_resource
  request_type = re.req_method
  search_param = re.search_param
  present = re.present
  present_code = re.intCode
  request_id = req.request_id
  res = Response.last request_id: request_id
  response_status = res.status

  CheckList.create resource: resource,
                   request_type: request_type,
                   search_param: search_param,
                   present: present,
                   present_code: present_code,
                   request_id: request_id,
                   response_status: response_status
end

# export to csv
cnames = []
CheckList.properties.to_a.each do |n|
    cnames.append(n.name.to_s)
end

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