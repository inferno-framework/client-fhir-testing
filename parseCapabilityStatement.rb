require 'json'
require 'csv'
require 'sqlite3'

json = File.read('resources/CapabilityStatement-us-core-client.json')
CapStat = JSON.parse(json)

# Interaction summary table
interaction = CSV.generate do |csv|
  csv << %w[type url valueCode code]
  CapStat['rest'][0]['resource'].each do |res|
    type = res['type']
    next unless res.include? 'interaction'

    res['interaction'].each do |hash|
      intarray = [type, hash['extension'][0]['url'], hash['extension'][0]['valueCode'], hash['code']]
      csv << intarray
      # puts(intarray)
    end
  end
end

puts interaction
File.write('resources/CapabilityStatement_interaction.csv', interaction)

# extension
extension = CSV.generate do |csv|
  csv << %w[type url valueCode]
  CapStat['rest'][0]['resource'].each do |res|
    type = res['type']
    next unless res.include? 'extension'

    csv << res['extension'][0].values.unshift(type)
    next unless res['extension'].length > 1
    next unless res['extension'][1].include? 'extension'

    res['extension'][1]['extension'].each do |ext|
      csv << ext.values.unshift(type)
    end
  end
end

puts(extension)
File.write('resources/CapabilityStatement_extension.csv', extension)

# searchParam
searchparam = CSV.generate do |csv|
  csv << %w[Type url valueCode name type]
  CapStat['rest'][0]['resource'].each do |res|
    type = res['type']
    next unless res.include? 'searchParam'

    res['searchParam'].each do |s|
      s1 = s['extension'][0].values.unshift(type)
      s1 << s['name']
      s1 << s['type']
      csv << s1
    end
  end
end

puts(searchparam)
File.write('resources/CapabilitySatement_searchParam.csv', searchparam)

# sqllite
db = SQLite3::Database.new('resources/CapabilityStatement.db')
rows = db.execute <<-SQL
  create table interaction (
    type varchar(30),
    url varchar(100),
    valueCode varchar(30),
    code varchar(30)
  );
SQL


CSV.parse(interaction, headers: true) do |row|
  db.execute "insert into interaction values ( ?, ?, ?, ? )", row.fields
end

db.execute( "select * from interaction limit 3" )

db.execute <<-SQL
  create table searchparam (
    type varchar(30),
    url varchar(100),
    valueCode varchar(30),
    name varchar(30),
    stype varchar(30)
  );
SQL

CSV.parse(searchparam, headers: true) do |row|
  db.execute "insert into searchparam values ( ?, ?, ?, ?, ? )", row.fields
end

db.execute( "select * from searchparam limit 3" )