require 'dm-core'
require 'yaml'

opts = YAML.load_file('proxy.yml')

# DataMapper.setup :default, "sqlite://#{Dir.pwd}/resources/CapabilityStatement-us-core-client.db"
DataMapper.setup :default, "sqlite://#{Dir.pwd}/" + opts[:db]

class Interaction
  include DataMapper::Resource

  property :id, Serial
  property :type, String
  property :url, String
  property :valueCode, String
  property :code, String
end

class SearchParam
  include DataMapper::Resource

  property :id, Serial
  property :type, String
  property :url, String
  property :valueCode, String
  property :name, String
  property :definition, String
  property :stype, String
end

class SearchCriteria
  include DataMapper::Resource

  property :id, Serial
  property :res_type, String
  property :profiles, String
  property :s_searches, String
  property :c_searches, String
  property :includes, String
  property :revincludes, String
  property :opterations, String
end