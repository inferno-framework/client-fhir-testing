require 'dm-core'
require 'yaml'
require_relative './CapabilityStatement-db'

opts = YAML.load_file(File.join(File.dirname(__FILE__), 'proxy.yml'))
DataMapper.setup :default, "sqlite://#{File.dirname(__FILE__)}/" + opts[:db]

# Checklist table for US Core Client Capability Statements
# id: serial number
# resource: FHIR resource
# interaction: read / vread / update / create / search-type
# conformance expectation: The matched interaction Code (SHALL/SHOULD/MAY) in the interaction table.
# expectation met: parameter in list and response status is 200-299
# request_ids: Requests that demonstrated the requirement was met
class CheckList

  include DataMapper::Resource

  property :id, Serial
  property :resource, String
  property :interaction, String
  property :conformance_expectation, String
  property :expectation_met, Boolean
  property :request_ids, String
  property :search_param, String

  # If checklist table is empty, get info from Interaction table to initialize Checklist table
  # otherwise just reset so that expectation_met is false for all requirements
  def self.initialize(attributes = nil)
    if CheckList.count == 0
        Interaction.each do |n|
          resource = n.type #FHIR resource
          interaction = n.code # interaction: read / vread / update / create / search-type
          conformance_expectation = n.valueCode # interaction Code (SHALL/SHOULD/MAY)
          expectation_met = false # boolean, parameter in list and response status is 200, default to False
          request_ids = '' # Requests that demonstrated the requirement, default to none/empty string
          search_param = '' # Array of search parameters. nil if not 'search-type'
          CheckList.create resource: resource,
                           interaction: interaction,
                           conformance_expectation: conformance_expectation,
                           expectation_met: expectation_met,
                           request_ids: request_ids,
                           search_param: search_param
        end
    else
      Interaction.each do |n|
        id = n.id
        requirement = CheckList.get(id)
        requirement.expectation_met = false
        requirement.request_ids = ''
        requirement.search_param = ''
        requirement.save
        end
      end
    end
  end


