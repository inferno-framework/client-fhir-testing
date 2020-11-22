require 'rack'
require_relative './fhir-proxy.rb'

# FHIR_PROXY_BACKEND="https://r4.smarthealthit.org" rackup config.ru -p 9292 -o 0.0.0.0
run FHIRProxy.new
