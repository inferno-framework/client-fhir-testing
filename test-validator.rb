require 'yaml'
require 'uri'
require 'csv'
require 'dm-migrations'
require_relative './CapabilityStatement-datamapper'
require_relative './CapabilityStatement-db'
require_relative './checklist-db'
require_relative './parse-request'
require_relative './datatypes-check'

opts = YAML.load_file(File.join(File.dirname(__FILE__), 'proxy.yml'))
endpoint = URI::HTTP.build(host: opts[:Host], port: opts[:Port])

# DataMapper.auto_migrate!
DataMapper.auto_upgrade!

include CheckDatatypes

# For each request, check if it's in US Core Capability Statement interaction table.
# If it is and the request was successful, in the checklist:
# - change requirement met = true, and
# - add request id to checklist
Request.each do |req|
  re = ParseRequest.new(req, endpoint.to_s)
  re.update
  present = re.present # The matched serial id in the interaction table.
  search_param = re.search_param # Array of search parameters. nil if not 'search-type'
  request_id = req.request_id
  res = Response.last request_id: req.request_id
  response_status = res.status

  if present != 0
    record = CheckList.get(present)
    # TODO: find a better way to store request_ids instead of a string in the checklist table
    # but for now check if this request_id is already listed by
    # checking substring
    if response_status.to_i >= 200 and response_status.to_i < 300 and !record.request_ids.include?(request_id.to_s + ",")
      record.expectation_met = true
      record.request_ids += (request_id.to_s + ",")
      # Add search parameters to checklist. Each bracketed list is a combination of search parameters for a request.
      # Example: For a column with search_param: ["gender", "name"],["_id"],
      # there were requests for "/Patient?gender=male&birthdate=1936-06-07" and "/Patient?_id=e86e9cae-89a3-44bf-9033-32a2d56f5113"
      if re.search_param != nil and !record.search_param.include?(re.search_param.to_s + ",") # each combination of search parameters is only listed once
        record.search_param += (search_param.to_s + ",")
      end

    end
    record.save
  end
end

# add column names in csv
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