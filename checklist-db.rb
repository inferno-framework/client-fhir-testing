require 'dm-core'
require 'yaml'

opts = YAML.load_file('proxy.yml')
DataMapper.setup :default, "sqlite://#{Dir.pwd}/" + opts[:db]

class CheckList
  include DataMapper::Resource

  property :id, Serial
  property :resource, String
  property :request_type, String
  property :search_param, String
  property :search_valid, Boolean
  property :search_combination, String
  property :present, Integer
  property :present_code, String
  property :request_id, Integer
  property :response_status, Integer
end
