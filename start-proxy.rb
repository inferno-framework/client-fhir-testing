require 'rack'
require 'yaml'
require_relative './fhir-proxy.rb'

# Options for Rack are listed here
# https://github.com/rack/rack/blob/master/lib/rack/server.rb
#
begin
  proxy_options = YAML.load_file('proxy.yml')
rescue Errno::ENOENT
  puts "Could not find file 'proxy.yml'"
  puts 'Creating one with default values'
  proxy_options = {
      Host: '0.0.0.0',
      Port: 9292,
      backend: 'https://r4.smarthealthit.org',
      db: 'fhir-transactions.db'
  }
  File.write('proxy.yml', proxy_options.to_yaml)
end
Rack::Server.start(
  app: FHIRProxy.new(
      'backend': proxy_options[:backend],
      'db': proxy_options[:db]
  ),
  Host: proxy_options[:Host],
  Port: proxy_options[:Port]
)
