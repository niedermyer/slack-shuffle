require 'sinatra'
require 'httparty'
require 'yaml'

# ENV['TEAM_NAMES'] stored as ; delimited list of names (i.e. Jane;John;Chris)


post('/') do
  HTTParty.post(ENV['WEBHOOK_URL'], body: { text: text, channel: "\##{params['channel_name']}", icon_emoji: ENV['ICON_EMOJI'], username: ENV['USERNAME'] }.to_json )
end

def text
  names = ENV['TEAM_NAMES']..split(/,/)
  names.shuffle.join(', ')
end