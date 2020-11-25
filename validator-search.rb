require_relative 'CapabilityStatement-db'

module ValidSearch
  def valid_shall(req_resource, search_param)
    criteria = SearchCriteria.first res_type: req_resource
    if criteria.s_searches.nil?
      false
    else
      (search_param - criteria.s_searches.split(', ')).length < search_param.length
    end
  end
end
