require 'rack-proxy'

class FHIRProxy < Rack::Proxy

  def initialize(app = nil, opts = {})
    super()
    @streaming = false
    File.open('log.txt', 'w') { |f| f.write "#{Time.now} - User logged in\n" }

    dst = ENV['FHIR_PROXY_BACKEND']
    if dst && URI(dst).is_a?(URI::HTTP)
      @backend = URI(dst)
      msg = %(@backend set to: #{dst})
      FHIRProxy.msg_out(msg)
    else
      msg = <<~HELP_DOC
        FHIR_PROXY_BACKEND environment variable not set or bad URI.
        Please specify proxy destination.
        Example: FHIR_PROXY_BACKEND="https://r4.fhir-server-dest.com" rackup config.ru -p 9292 -o 0.0.0.0
      HELP_DOC
      FHIRProxy.msg_out(msg)
      exit(1)
    end
  end

  def rewrite_env(env)
    #@backend = URI('https://r4.smarthealthit.org')
    #@streaming = false
    #env['HTTP_HOST'] = 'r4.smarthealthit.org'
    env['HTTP_HOST'] = @backend.host
    FHIRProxy.msg_out("#{Time.now} - Rewrite env...")
    FHIRProxy.msg_out(env.to_s, false)
    return env
  end

  def rewrite_response(triplet)
    status, headers, body = triplet
    # headers["content-length"] = body.bytesize.to_s
    FHIRProxy.msg_out("#{Time.now} - Rewrite response...")
    if headers['Location']
      FHIRProxy.msg_out('  Redirect in response header')
      # headers["Location"]
    end
    FHIRProxy.msg_out('  ' + status.to_s, false)
    FHIRProxy.msg_out('  ' + headers.to_s, false)
    FHIRProxy.msg_out('  ' + body.to_s, false)
    return triplet
  end

  def self.msg_out(msg, stdout = true, file = true)
    puts msg if stdout
    File.write('log.txt', "#{msg} \n", mode: 'a') if file
  end

end
