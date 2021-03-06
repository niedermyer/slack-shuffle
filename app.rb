require 'sinatra'
require 'slack-ruby-client'
require 'httparty'
require 'json'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

# Slack Ruby client
client = Slack::Web::Client.new

post('/standup') do
  payload = JSON.parse(request.body.read).symbolize_keys

  log(message: payload)

  icon = payload[:icon] || ENV['ICON_EMOJI']
  channel = payload[:channel] || ENV['CHANNEL_OR_USER']
  shuffled_team_list = shuffled_names(payload[:team_names])
  day_of_week = payload[:day_of_week] || Time.now.strftime('%A')
  standup_url = payload[:standup_url]

  fallback_and_notification_text = "Standup Time! Join at #{standup_url}"

  blocks = [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "<!here> *Happy #{day_of_week}!*"
      },
      "accessory": {
        "type": "button",
        "text": {
          "type": "plain_text",
          "text": "Join Standup"
        },
        "style": "primary",
        "url": standup_url,
        "action_id": "join_standup"
      }
    },
    {
      "type": "divider"
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": shuffled_team_list
      },
    }
  ]

  client.chat_postMessage(text: fallback_and_notification_text, blocks: blocks, channel: channel, icon_emoji: icon, username: 'Standup Time!', as_user: false)

  status :ok
end

post('/estimate') do
  log(message: params)

  icon = ':game_die:'

  user = HTTParty.get("https://slack.com/api/users.info?token=#{ENV['SLACK_API_TOKEN']}&user=#{params['user_id']}&pretty=1" )['user']
  user_real_name = user['real_name']

  username = "#{user_real_name}'s Estimate"

  estimate = params['text']

  blocks = [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "********"
      },
      "accessory": {
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
            "text": "Nevermind"
          }
        }
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
          "value": estimate,
          "action_id": "reveal"
        }
      ]
    }
  ]

  client.chat_postMessage(blocks: blocks.to_json, channel: params['channel_id'], icon_url: user['profile']['image_48'], username: username, as_user: false)
  client.chat_postEphemeral(text: "Estimate of #{estimate} sent", user: user['id'], channel: params['channel_id'], icon_emoji: icon, username: username, as_user: false)

  status :ok
end

post('/response') do
  log(message: params['payload'], delimiter: '-')

  icon = ':game_die:'
  username = "Story Estimate"

  request_data = JSON.parse(params['payload'])
  action = request_data['actions'][0]

  user = HTTParty.get("https://slack.com/api/users.info?token=#{ENV['SLACK_API_TOKEN']}&user=#{request_data['user']['id']}&pretty=1" )['user']
  user_real_name = user['profile']['real_name']

  log(message: action)
  log(message: action['action_id'])

  case action['action_id']
  when 'reveal'
    estimate = action['value']

    blocks = [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": estimate
        },
        "accessory": {
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
              "text": "Nevermind"
            }
          }
        }
      }
    ]

    body = { blocks: blocks, channel: ENV['CHANNEL_OR_USER'], icon_emoji: icon, username: username, as_user: false }.to_json

    response = HTTParty.post(request_data['response_url'], body: body )

    log(message: response)
    status 200
  when 'delete'
    ts = request_data['message']['ts']
    channel = request_data['channel']['id']

    body = {
      channel: channel,
      ts: ts,
      as_user: true
    }
    response = client.chat_delete(body)

    log(message: response)
    status 200
  end

  status 200
end

get('/good-morning') do
  logger.info("Good morning! I'm waking up, and preparing for the day!")
  status :ok
end

def shuffled_names(name_list)
  # ENV['TEAM_NAMES'] stored as a comma delimited list of names (i.e. Jane, John, Chris).
  # Leading and trailing whitespace will be stripped.

  name_list = name_list || ENV['TEAM_NAMES']

  names = name_list.split(/,/).map(&:strip)
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
