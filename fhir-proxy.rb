require 'rack-proxy'
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
    # Proxy works by rewriting incoming request, then performing the request, finally re-writing the response
    # rewrite_response(perform_request(rewrite_env(env)))
    # --
    # Initial 'env' before rewriting should contain enough info for original http request
    # https://stackoverflow.com/questions/15458334/how-to-read-post-data-in-rack-request
    # source_request = Rack::Request.new(env)
    # JSON.parse(source_request.body.read)
    req_to_proxy = rewrite_env(env)
    request = Rack::Request.new(env)
    data = request.body.read
    req_id = @fhir_db.insert_request(env['REQUEST_METHOD'], env['REQUEST_PATH'], data.to_s)
    res_from_proxy = rewrite_response(perform_request(req_to_proxy))
    status, headers, body = res_from_proxy
    @fhir_db.insert_response(req_id, body.to_s)
    return [status, headers, body]
  end

  def rewrite_env(env)
    env['HTTP_HOST'] = @backend.host
    msg_out("#{Time.now} - Rewrite env...")
    # Add uuid to http request for tracking, apparently, this is the standard way of tracking
    # But I think the FHIR server is not responding with this header...
    # https://stackoverflow.com/questions/23651411/http-request-uuid-or-request-start-time-in-ruby-applications
    # env['HTTP_X_REQUEST_ID'] = env['HTTP_X_REQUEST_ID'] || SecureRandom.uuid
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
    msg_out('  ' + status.to_s, false)
    msg_out('  ' + headers.to_s, false)
    msg_out('  ' + body.to_s, false)
    return triplet
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
