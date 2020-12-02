# hello.rb
require 'sinatra'
require 'csv'
include FileUtils::Verbose

get '/' do
  files = Dir["public/uploads/**/*.csv"]
  @previous = files
  erb :upload
end

get '/upload' do
  erb :test
end

get '/uploaded' do
  @word = "HELLOW HELLOW HELLOW"
  erb :uploaded
end

post '/upload-submit' do
  file_data = params[:resultsfile][:tempfile].read
  temp_file = params[:resultsfile][:tempfile]
  csv_rows  = CSV.parse(file_data, headers: true)
  # csv_rows.map do |rows|
  #   puts rows['key']
  #   # rows['key']
  # end
  @results = csv_rows
  cp(temp_file,"public/uploads/test7.csv")
  erb :uploaded
end
