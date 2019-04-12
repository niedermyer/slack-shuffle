require 'sinatra'
require 'httparty'
require 'yaml'

data = YAML.load_file(File.expand_path("./data.yml"))

post('/') do
  HTTParty.post(ENV['WEBHOOK_URL'], body: { text: ENV['TEAM_NAMES'].shuffle.join(', '), channel: "\##{params['channel_name']}", icon_emoji: ENV['ICON_EMOJI'], username: ENV['USERNAME'] }.to_json )
end
