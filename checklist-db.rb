require 'dm-core'
require 'yaml'

opts = YAML.load_file(File.join(File.dirname(__FILE__), 'proxy.yml'))
DataMapper.setup :default, "sqlite://#{File.dirname(__FILE__)}/" + opts[:db]

class CheckList
  # id: serial number
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

  include DataMapper::Resource

  property :id, Serial
  property :resource, String
  property :request_type, String
  property :search_param, String
  property :search_valid, Boolean
  property :search_combination, String
  property :search_type, String
  property :present, Integer
  property :present_code, String
  property :request_id, Integer
  property :request_uri, String
  property :response_status, Integer
end
