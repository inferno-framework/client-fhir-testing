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
  def initialize(endpoint)
    @req = Request.last
    @endpoint = endpoint
  end

  # get latest request recode by request_uri
  # get_request_byURI('/Patient?gender=male')
  def get_request_byURI(request_uri)
    @req = Request.last(:request_uri.like => request_uri)
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
  def request_params
    req_query = URI(@req.request_uri).query
    req_params = nil
    unless req_query.nil?
      req_params = URI::decode_www_form(req_query).to_h
    end
    req_params
  end

  # get request method
  def request_method
    @req.request_method
  end
end