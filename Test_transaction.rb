require 'json'
require 'uri'
require 'minitest/autorun'
require_relative 'CapabilityStatement-db'
require_relative 'parse-transaction'
require_relative 'generateReport'

class Test_req_res < Minitest::Test
  def setup
    @request = Request.get(1)
    @response = Response.get(1)
    # @rReportGen= ReportGen.new('fhir-transactions.db')
    # @rReportGen.generateReport
  end

  def test_status
    assert_equal '200', @response.status
  end

  def test_patient_id
    # request
    req = @request.request_uri
    req_param = URI::decode_www_form(URI(req).query).to_h
    search_param = SearchParam.all type: 'Patient'
    params = Array.new()
    search_param.each do |name|
      params.append(name.name)
    end
    param_subset = Set.new(req_param.keys).subset? Set.new(params)
    assert_equal param_subset, true, req_param.keys[0] + ' not valid search parameter for Patient'

    # response
    res_data = JSON.parse(JSON.parse(@response.data)[0])
    patient_id = res_data['entry'][0]['resource']['id']

    assert_equal req_param['_id'], patient_id


  end

  def test_resource_type
    req_resource = URI.parse(@request.request_uri).path.split('/')[-1]
    res_data = JSON.parse(JSON.parse(@response.data)[0])
    res_type = res_data['entry'][0]['resource']['resourceType']

    assert_equal req_resource, res_type
  end
end