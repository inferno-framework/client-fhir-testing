require 'rack-proxy'
require 'json'
require_relative 'fhir-transaction-db.rb'

class FHIRProxy < Rack::Proxy
  attr_accessor :config_mode # global var
  def initialize(myopts = {}, app = nil, opts = {})
    super(app, opts)
    @streaming = false
    File.open('log.txt', 'w') { |f| f.write "#{Time.now} - User logged in\n" }
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

    msg_out("#{Time.now} - Rewrite env...")
    # Standard way of tracking http sessions is w/ uuid based header.
    # But I don't think the FHIR server is responding with this header.
    # env['HTTP_X_REQUEST_ID'] = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid

    # == filter request from UI to configure
    request = Rack::Request.new(env)
    if request.path.match('/fc_config')
      self.config_mode = true
      @read_timeout = 240
      @ssl_verify_none = true
      myArray = request.query_string.split('destination=',2)
      dst = myArray[1]
      msg = %(@backend set to: #{dst})
      if dst && URI(dst).is_a?(URI::HTTP) && dst.include?('http:')
        @backend = URI(dst)
        # @port shouldn't be needed and would break any http not on standard port
        # @port = 80
        msg_out(msg)
      elsif  dst && URI(dst).is_a?(URI::HTTP) && dst.to_s.include?('https:')
        @backend = URI(dst)
        @use_ssl= true
        # env["HTTP_X_FORWARDED_PROTO"] = 'https'
        msg_out(msg)
      end
    end
    env['HTTP_HOST'] = @backend.host
    msg_out('  ' + env.to_s, false)
    return env
  end

  def rewrite_response(triplet)
    status, headers, body = triplet
    # headers["content-length"] = body.bytesize.to_s
    msg_out("#{Time.now} - Rewrite response...")
    if headers['Location']
      msg_out('  Redirect in response header')
      # headers["Location"]
      # TODO: Do we want to handle redirects?
    end
    if self.config_mode  == true
      # if config mode is true ->
      # overwrite status, headers, body to proper response based on what has been configured.
      # As a default Proxy returns status 301. Change it to 200, fill proper header and body to return response back to UI.
      self.config_mode  = false
    end
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
    @db_name = myopts[:db] || 'fhir-transactions.db'
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
