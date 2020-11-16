require 'json'
require 'dm-migrations'
require_relative './CapabilityStatement-db'

DataMapper.auto_migrate!
DataMapper.auto_upgrade!

json = File.read('resources/CapabilityStatement-us-core-client.json')
CapStat = JSON.parse(json)

# Interaction summary table
CapStat['rest'][0]['resource'].each do |res|
  type = res['type']
  next unless res.include? 'interaction'

  res['interaction'].each do |hash|
    url = hash['extension'][0]['url']
    valueCode = hash['extension'][0]['valueCode']
    code = hash['code']
    Interaction.create type: type, url: url, valueCode: valueCode, code: code
  end
end

# SearchParam
CapStat['rest'][0]['resource'].each do |res|
  type = res['type']
  next unless res.include? 'searchParam'

  res['searchParam'].each do |s|
    url = s['extension'][0]['url']
    valueCode = s['extension'][0]['valueCode']
    name = s['name']
    definition = s['definition']
    stype = s['type']
    SearchParam.create type: type, url: url, valueCode: valueCode,
                       name: name, definition: definition, stype: stype
  end
end

# Interaction.get(1)
# int1 = Interaction.all type: 'Patient', valueCode: 'SHOULD'
# puts(int1[0].code)
# SearchParam.get(1)
#
# extension
