require 'sinatra'
require 'slack-ruby-client'
require 'httparty'
require 'json'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

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

  icon = ':game_die:'
  username = "Story Estimate"

  user = HTTParty.get("https://slack.com/api/users.info?token=#{ENV['SLACK_API_TOKEN']}&user=#{params['user_id']}&pretty=1" )['user']
  user_real_name = user['profile']['real_name']

  estimate = params['text']
  text = "#{user_real_name} ********"
  blocks = [
    {
      "type": "context",
      "elements": [
        {
          "type": "mrkdwn",
          "text": "*Author:* #{user_real_name}"
        }
      ]
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "********"
      }
    },
    {
      "type": "actions",
      "elements": [
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "Reveal Estimate"
          },
          "style": "primary",
          "value": "reveal",
          "action_id": "reveal"
        },
        {
          "type": "button",
          "text": {
            "type": "plain_text",
            "text": "Delete"
          },
          "style": "danger",
          "value": "delete",
          "action_id": "delete",
          "confirm": {
            "title": {
              "type": "plain_text",
              "text": "Delete #{user_real_name}'s Estimate?"
            },
            "text": {
              "type": "mrkdwn",
              "text": "Are you sure that you want to delete this estimate?"
            },
            "confirm": {
              "type": "plain_text",
              "text": "Yes, delete it!"
            },
            "deny": {
              "type": "plain_text",
              "text": "Nevermind, I'll keep it"
            }
          }
        }
      ]
    }
  ]

  body = { text: text, blocks: blocks, channel: ENV['CHANNEL_OR_USER'], icon_emoji: icon, username: username }.to_json


  HTTParty.post(ENV['WEBHOOK_URL'], body: body )

  "Estimate of #{estimate} sent to #{ENV['CHANNEL_OR_USER']}"
end

post('/response') do
  logger.info('I GOT A RESPONSE!!!!')
  log(message: params, delimiter: '-')
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
