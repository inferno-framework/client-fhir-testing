require 'yaml'
require 'uri'

require_relative 'CapabilityStatement-datamapper'
require_relative 'CapabilityStatement-db'
require_relative 'checklist-db'
require_relative 'parse-request'

opts = YAML.load_file('proxy.yml')
endpoint = URI::HTTP.build(host: opts[:Host], port: opts[:Port])

Request.each do |req|
  re = ParseRequest.new(req, endpoint.to_s)
  resource = re.request_action[0]
  request_type = re.request_method
  search_param = re.search_param
  re.interaction_present
  present = re.present
  request_id = req.request_id
  res = Response.last request_id: request_id
  response_status = res.status

  CheckList.create resource: resource,
                   request_type: request_type,
                   search_param: search_param,
                   present: present,
                   request_id: request_id,
                   response_status: response_status
end