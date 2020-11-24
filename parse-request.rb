require_relative 'CapabilityStatement-db'
require_relative 'parse-transaction'
# require 'postman-ruby'
require 'json'
require 'uri'

# https://apievangelist.com/2019/09/18/creating-a-postman-collection-for-the-fast-healthcare-interoperability-resources-fhir-specification/
# p = Postman.parse_file('resources/fhir_postman.json')
# filtered = p.filter('method' => 'GET', 'url' => '/.(\/patient\/).*/i')
# p = JSON.parse(File.read('resources/fhir_postman.json'))
# p['folders']

# endpoint = 'http://0.0.0.0:9595'
# back_end = 'http://r4.smarthealthit.orgreq'

# Patient
# read
# http://0.0.0.0:9595/Patient/e62229aa-7327-48d5-bbe8-6b8295de0e55
# vread
# http://0.0.0.0:9595/Patient/e62229aa-7327-48d5-bbe8-6b8295de0e55/_history/5
# search
# http://0.0.0.0:9595/Patient?gender=male
# create
# http://0.0.0.0:9595/Patient


class ParseRequest
  def initialize(req, endpoint)
    @req = req
    @endpoint = endpoint
    @req_params = nil
    @present = 0
    @intCode = nil
  end

  # get request action/resource
  # request_action('http://0.0.0.0:9595', Request.get(61))
  # request_action('http://0.0.0.0:9595', Request.get(71))
  def request_action
    path = URI(@endpoint).path
    action = URI(@req.request_uri).path.sub(path, '').split('/')
    action -= ['']
    if action.include?('_history')
      [action[0], '_history']
    else
      [action[0]]
    end
  end

  # get search params
  # request_params(Request.get(61))
  def request_params_hash
    req_query = URI(@req.request_uri).query
    unless req_query.nil?
      @req_params = URI::decode_www_form(req_query).to_h
    end
    @req_params
  end

  def search_param
    if @req_params.nil?
      nil
    else
      @req_params.keys
    end
  end

  # get request method
  def request_method
    if @req_params.keys.include? '_history'
      'vread'
    else
      @req.request_method
    end
  end

  def interaction_present
    method_codes = {'GET'=>'create', 'PUT'=>'update', 'POST'=>'create', 'vread'=>'vread'}
    int1 = Interaction.last type: req.fhir_action, code: method_codes[req.request_method]
    if int1.nil?
      @present = 0
    else
      @present = 1
    end
    @intCode = @int1.valueCode
  end


end