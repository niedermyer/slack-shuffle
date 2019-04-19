require 'sinatra'
require 'httparty'
require 'yaml'

# ENV['TEAM_NAMES'] stored as ; delimited list of names (i.e. Jane;John;Chris)

# TODO: delete this endpoint and OLD_WEBHOOK_URL after completion of new endpoints
post('/') do
  HTTParty.post(ENV['OLD_WEBHOOK_URL'], body: { text: text, channel: ENV['CHANNEL_OR_USER'], icon_emoji: ENV['ICON_EMOJI'], username: ENV['USERNAME'] }.to_json )
end

post('/standup') do
  log(message: params)

  icon = params['icon'] || ENV['ICON_EMOJI']
  channel = params['channel'] || ENV['CHANNEL_OR_USER']
  text = params['text'] || default_text

  HTTParty.post(ENV['OLD_WEBHOOK_URL'], body: { text: text, channel: channel, icon_emoji: icon, username: ENV['USERNAME'] }.to_json )
end

post('/estimate') do
  log(message: params)

  icon = ':game_die:'
  username = "Story Estimate"

  estimate = params['text']
  text = "<@#{params['user_id']}> ********"
  attachment = [
    {
      "type": "context",
      "elements": [
        {
          "type": "mrkdwn",
          "text": "*Author:* <@#{params['user_id']} | real_name>"
        }
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "********"
      },
      "accessory": {
        "type": "overflow",
        "options": [
          {
            "text": {
              "type": "plain_text",
              "text": "Delete Estimate",
              "emoji": true
            },
            "value": "delete"
          }
        ]
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "Reveal",
            "emoji": true
          },
          "value": "reveal"
        }
      ]
    }
  ]

  HTTParty.post(ENV['OLD_WEBHOOK_URL'], body: { text: text, attachment: attachment, channel: ENV['CHANNEL_OR_USER'], icon_emoji: icon, username: username }.to_json )

  "Estimate of #{estimate} sent to ENV['CHANNEL_OR_USER']"
end


def default_text
  names = ENV['TEAM_NAMES'].split(/;/)
  names = names.shuffle
  names = names.map.with_index(1) { |name, i| "#{i}. #{name}\n" }
  names.join
end

def log(message:, delimiter: '*')
  logger.info delimiter*80
  logger.info ''
  logger.info message
  logger.info ''
  logger.info delimiter*80

end
