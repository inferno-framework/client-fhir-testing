require 'rack'
require_relative './fhir-proxy.rb'

# rackup config.ru -p 9292 -o 0.0.0.0
run FHIRProxy.new
