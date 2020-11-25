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

  def combine_search(req_resource, search_param)
    if search_param.length < 2
      return nil
    end

    criteria = SearchCriteria.first res_type: req_resource
    c_searches = criteria.c_searches.split(", ")
    valid_comb = []
    c_searches.each do |cs|
      if (cs.split('+') - search_param).length == 0
        valid_comb.append(cs)
      end
    end
    return valid_comb
  end
end
