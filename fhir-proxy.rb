require 'rack-proxy'
require 'json'
require_relative 'fhir-transaction-db.rb'

class FHIRProxy < Rack::Proxy
  def initialize(app = nil, opts = {})
    super(app, opts)
    @streaming = false
    File.open('log.txt', 'w') { |f| f.write "#{Time.now} - User logged in\n" }
    set_backend_or_die
    @fhir_db = FHIRTransactionDB.new('fhir-transactions.db')
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
        @port = 80
        msg_out(msg)
      elsif  dst && URI(dst).is_a?(URI::HTTP) && dst.to_s.include?('https:')
        @backend = URI(dst)
        @use_ssl= true
        #env["HTTP_X_FORWARDED_PROTO"] = 'https'
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
    method = env['REQUEST_METHOD']
    req_uri = env['REQUEST_URI']
    # TODO: Need to store all non-objects? from env, not just http
    headers = self.class.extract_http_request_headers(request.env)
    data = request.body.read
    req_id = @fhir_db.insert_request(method, req_uri, headers.to_json, data.to_s)
    return req_id
  end

  def record_response(triplet, req_id)
    status, headers, body = triplet
    res_id = @fhir_db.insert_response(req_id, status, headers.to_json, body.to_s)
    return res_id
  end

  def msg_out(msg, stdout = true, file = true)
    # can change this function to change how we do basic logging
    puts msg if stdout
    File.write('log.txt', "#{msg} \n", mode: 'a') if file
  end

  def set_backend_or_die
    dst = ENV['FHIR_PROXY_BACKEND']
    if dst && URI(dst).is_a?(URI::HTTP)
      @backend = URI(dst)
      msg_out("@backend set to: #{dst}")
    else
      msg = <<~HELP_DOC
        FHIR_PROXY_BACKEND environment variable not set or bad URI.
        Please specify proxy destination.
        Example: FHIR_PROXY_BACKEND="https://r4.fhir-server-dest.com" rackup config.ru -p 9292 -o 0.0.0.0
      HELP_DOC
      msg_out(msg)
      exit(1)
    end
  end

end
