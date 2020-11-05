require 'rack-proxy'

class FHIRProxy < Rack::Proxy

  def initialize(app = nil, opts = {})
    super(app, opts)
    @streaming = false
    File.open('log.txt', 'w') { |f| f.write "#{Time.now} - User logged in\n" }

    dst = ENV['FHIR_PROXY_BACKEND']
    if dst && URI(dst).is_a?(URI::HTTP)
      @backend = URI(dst)
      msg = %(@backend set to: #{dst})
      msg_out(msg)
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

  def rewrite_env(env)
    # Proxy source file
    # https://github.com/ncr/rack-proxy/blob/master/lib/rack/proxy.rb
    # Proxy works by rewriting incoming request, then performing the request, finally re-writing the response
    # rewrite_response(perform_request(rewrite_env(env)))
    #
    # Initial 'env' before rewriting should contain enough info for original http request
    # https://stackoverflow.com/questions/15458334/how-to-read-post-data-in-rack-request
    # source_request = Rack::Request.new(env)
    # JSON.parse(source_request.body.read)
    env['HTTP_HOST'] = @backend.host
    msg_out("#{Time.now} - Rewrite env...")
    msg_out(env.to_s, false)
    return env
  end

  def rewrite_response(triplet)
    status, headers, body = triplet
    # headers["content-length"] = body.bytesize.to_s
    msg_out("#{Time.now} - Rewrite response...")
    if headers['Location']
      msg_out('  Redirect in response header')
      # headers["Location"]
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

end
