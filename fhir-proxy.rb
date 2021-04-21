require 'rack-proxy'
require 'json'
require_relative 'fhir-transaction-db.rb'
require_relative 'data-Mapper'
class FHIRProxy < Rack::Proxy
  attr_accessor :config_mode, :result_mode ,:record_mode, :landingpage_mode# global var

  def initialize(myopts = {}, app = nil, opts = {})
    super(app, opts)
    time = Time.new
    #set 'time' equal to the current time.
    time = time.hour.to_s + ":" + time.min.to_s
    @startTime = time
    @startId = 0
    @endId = 0
    @streaming = false
    File.open('log.txt', 'w') { |f| f.write "#{Time.now} - Proxy started.\n" }
    parse_myopts(myopts)
    @fhir_db = FHIRTransactionDB.new(@db_name)
  end

  def call(env)
    # Proxy source file
    # https://github.com/ncr/rack-proxy/blob/master/lib/rack/proxy.rb
    # rewrite_response(perform_request(rewrite_env(env)))
    # --
    # Client -> Proxy (Save req here) -> Server
    # Client <- (Save res here) Proxy <- Server
    new_env = rewrite_env(env)
    req_id = record_request(new_env)
    res_triple = rewrite_response(perform_request(new_env))
    res_id = record_response(res_triple, req_id)
    return res_triple
  end

  def rewrite_env(env)
    msg_out("\n#{Time.now} - Rewriting env")
    oreq = Rack::Request.new(env)
    msg_out('  client: ' + oreq.ip)
    msg_out('  request: ' + oreq.request_method + ' ' + oreq.url)
    # TODO: Not sure if we need to handle query string encoding...
    # ::Proxy uses Rack::Request.new(env).fullpath to create request to backend
    # .fullpath pulls from ENV['QUERY_STRING']
    # if QUERY_STRING needs to be encoded, we need to encode it bc ::Proxy does not
    # We encode the request here, but we record in the db the unencoded form ['REQUEST_URI']

    # params_encoded = URI.encode_www_form(oreq.params)
    # if env['QUERY_STRING'] != params_encoded
    #   env['QUERY_STRING'] = params_encoded
    #   msg_out('  encoding query string: ' + env['QUERY_STRING'])
    # end


    return env
  end

  def rewrite_response(triplet)
    status, headers, body = triplet
    # headers["content-length"] = body.bytesize.to_s
    msg_out("\n#{Time.now} - Rewriting response")
    msg_out('  status: ' + status.to_s)
    if headers['Location']
      msg_out("  redirect in response header to #{headers['Location']}")
      # TODO: Do we want to handle redirects?  As a future item.
      # Would need to change headers['Location'] to point to proxy
      # and @backend would need to be updated
    end
    msg_out('  returning response to client')
    msg_out('  ' + status.to_s, false)
    msg_out('  ' + headers.to_s, false)
    msg_out('  ' + body.to_s, false)
    return triplet
  end

  def record_request(env)
    request = Rack::Request.new(env)
    headers = get_all_headers(env)
    data = request.body.read
    req_id = @fhir_db.insert_request(headers, data, @backend.to_s)
    return req_id
  end

  def record_response(triplet, req_id)
    status, headers, body = triplet
    res_id = @fhir_db.insert_response(req_id, status, headers, body)
    return res_id
  end

  def get_all_headers(hash)
    headers = hash.reject do |k, v|
      v.nil? || !(v.is_a? String)
    end
    return headers
  end

  def msg_out(msg, stdout = true, file = true)
    # can change this function to change how we do basic logging
    puts msg if stdout
    File.write('log.txt', "#{msg} \n", mode: 'a') if file
  end

  def parse_myopts(myopts)
    @db_name = myopts[:db] || 'transactions.db'
    backend_str = ENV['FHIR_PROXY_BACKEND'] if ENV['FHIR_PROXY_BACKEND']
    backend_str = myopts[:backend] if myopts[:backend]
    if backend_str && URI(backend_str).is_a?(URI::HTTP)
      @backend = URI(backend_str)
      msg_out("@backend set to: #{@backend}")
    else
      msg = <<~HELP_DOC
        Proxy 'backend' config option not set or bad URI.
        Please specify proxy destination via proxy.yml file or environment variable FHIR_PROXY_BACKEND
        Example: "https://r4.smarthealthit.org"
      HELP_DOC
      msg_out(msg)
      exit(1)
    end
  end

end
