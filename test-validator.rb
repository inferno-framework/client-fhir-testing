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

opts = YAML.load_file(File.join(File.dirname(__FILE__), 'proxy.yml'))
endpoint = URI::HTTP.build(host: opts[:Host], port: opts[:Port])

# DataMapper.auto_migrate!
DataMapper.auto_upgrade!

include ValidSearch
include CheckDatatypes

# Get info from Interaction table to fill out Checklist table
# quick fix -- only do this if checklist table is empty.
# TODO: move this somewhere else where it'll only be called once
if CheckList.count == 0
  Interaction.each do |n|
    resource = n.type #FHIR resource
    interaction = n.code # interaction: read / vread / update / create / search-type
    conformance_expectation = n.valueCode # interaction Code (SHALL/SHOULD/MAY)
    expectation_met = false # boolean, parameter in list and response status is 200, default to False
    request_ids = '' # Requests that demonstrated the requirement, default to none/empty string
    CheckList.create resource: resource,
                     interaction: interaction,
                     conformance_expectation: conformance_expectation,
                     expectation_met: expectation_met,
                     request_ids: request_ids
  end
end


# resource: FHIR resource / action
# request_type: read / vread / update / create / search-type
# search_param: Array of search parameters. nil if not 'search-type'.
# search_valid: boolean, whether search is valid (parameter in SHALL list and response status is 200)
# search_combination: 1 parameter => nil; >1 parameters & find in the SHALL list => SHALL combinations; >1 parameters & not in the SHALL list => []
# search_type: Array of boolean. whether each search value is valid for its data type. nil if not 'search-type'.
# present: The matched serial id in the interaction table.
# present_code: The matched interaction Code (SHALL/SHOULD/MAY) in the interaction table.
# request_id: The original request ID from the request table in the database.
# request_uri: The original request uri from the test requests.
# response_status: The response status from server in the response table from database.
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

  if present != 0
    record = CheckList.get(present)
    # TODO: find a better way to store request_ids instead of a string in checklist table
    # but for now check if this request_id is already listed by
    # checking substring
    if !record.request_ids.include? (request_id.to_s + ",")
      record.request_ids += (request_id.to_s + ",")
    end

    if response_status == "200"
      record.expectation_met = true
    end
    record.save
  end

  # search_valid = nil
  # if re.search_param != nil
  #   search_valid = (response_status == "200") and valid_shall(re.req_resource, re.search_param)
  #   search_comb = combine_search(re.req_resource, re.search_param)
  #
  #   req_params = re.instance_variable_get(:@req_params)
  #   param_type = []
  #   req_params.each do |k, v|
  #     sp = SearchParam.first type: re.req_resource, name: k
  #     if sp.nil?
  #       param_type.append(nil)
  #     else
  #       param_type.append(check_types(v, sp.stype))
  #     end
  #   end
  # end

  #
  # CheckList.create resource: resource,
  #                  request_type: request_type,
  #                  search_param: search_param,
  #                  search_valid: search_valid,
  #                  search_combination: search_comb,
  #                  search_type: param_type,
  #                  present: present,
  #                  present_code: present_code,
  #                  request_id: request_id,
  #                  request_uri: request_uri,
  #                  response_status: response_status
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