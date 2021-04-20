require 'dm-core'
require 'yaml'
require_relative './CapabilityStatement-db'

opts = YAML.load_file(File.join(File.dirname(__FILE__), 'proxy.yml'))
DataMapper.setup :default, "sqlite://#{File.dirname(__FILE__)}/" + opts[:db]

class CheckList
  # id: serial number
  # resource: FHIR resource / action
  # interaction: read / vread / update / create / search-type
  # conformance expectation: The matched interaction Code (SHALL/SHOULD/MAY) in the interaction table.
  # expectation met: parameter in list and response status is 200
  # request_ids: Requests that demonstrated the requirement

  include DataMapper::Resource

  property :id, Serial
  property :resource, String
  property :interaction, String
  property :conformance_expectation, String
  property :expectation_met, Boolean
  property :request_ids, String
end

