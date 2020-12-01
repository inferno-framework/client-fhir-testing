require_relative './CapabilityStatement-db'
require_relative './parse-transaction'
# require 'postman-ruby'
require 'json'
require 'uri'

# endpoint = 'http://0.0.0.0:9595'
# back_end = 'http://r4.smarthealthit.orgreq'

# Patient
# read
# http://0.0.0.0:9595/Patient/e62229aa-7327-48d5-bbe8-6b8295de0e55
# vread
# http://0.0.0.0:9595/Patient/e62229aa-7327-48d5-bbe8-6b8295de0e55/_history/5
# search
# http://0.0.0.0:9595/Patient?gender=male
# create
# http://0.0.0.0:9595/Patient


class ParseRequest
  def initialize(req, endpoint)
    @req = req
    @endpoint = endpoint
    @req_params = nil
    @present = 0
    @intCode = nil
    @actions = nil
  end

  # get request action/resource
  # request_action('http://0.0.0.0:9595', Request.get(61))
  # request_action('http://0.0.0.0:9595', Request.get(71))
  #def request_action
  def update
    # actions
    path = URI(@endpoint).path
    action = URI(@req.request_uri).path.sub(path, '').split('/')
    action -= ['']
    if action.include?('_history')
      @actions = [action[0], '_history']
    else
      @actions = [action[0]]
    end

    # search param
    req_query = URI(@req.request_uri).query
    unless req_query.nil?
      @req_params = URI::decode_www_form(req_query).to_h
    end

    # requst method
    if @req.request_method == "GET" and @actions.include? '_history'
      @req_method = 'vread'
    elsif @req.request_method == "GET" and @req_params != nil
      @req_method = 'search-type'
    elsif @req.request_method == "PUT"
      @req_method = 'update'
    elsif @req.request_method == "POST"
      @req_method = 'create'
    else
      @req_method = 'read'
    end

    # interaction
    int1 = Interaction.last type: @actions[0], code: @req_method
    if int1.nil?
      @present = 0
    else
      @present = int1.id
      @intCode = int1.valueCode
    end
  end

  def present
    @present
  end

  def intCode
    @intCode
  end

  def req_resource
    @actions[0]
  end

  def search_param
    # @req_param = self.class.request_params_hash
    if @req_params.nil?
      nil
    else
      @req_params.keys
    end
  end

  def req_method
    @req_method
  end

end