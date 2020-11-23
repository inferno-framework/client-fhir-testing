require 'rack'
require 'yaml'
require_relative './fhir-proxy.rb'

# Options for Rack are listed here
# https://github.com/rack/rack/blob/master/lib/rack/server.rb
#
if ARGV[0].nil?
  opts_file = 'proxy.yml'
else
  opts_file = ARGV[0]
end

begin
  proxy_options = YAML.load_file(opts_file)
  puts "Loading options from file #{opts_file}"
rescue Errno::ENOENT
  puts "Could not find file #{opts_file}"
  puts "Creating #{opts_file} with default values"
  proxy_options = {
      Host: '0.0.0.0',
      Port: 9292,
      backend: 'https://r4.smarthealthit.org',
      db: 'transactions.db'
  }
  File.write(opts_file, proxy_options.to_yaml)
rescue StandardError => e
  puts e
end
Rack::Server.start(
  app: FHIRProxy.new(
      'backend': proxy_options[:backend],
      'db': proxy_options[:db]
  ),
  Host: proxy_options[:Host],
  Port: proxy_options[:Port]
)
