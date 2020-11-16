require 'dm-core'

# DataMapper.setup :default, "sqlite://#{Dir.pwd}/resources/CapabilityStatement-us-core-client.db"
DataMapper.setup :default, "sqlite://#{Dir.pwd}/fhir-transactions.db"

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

