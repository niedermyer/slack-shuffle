require 'sinatra'
require 'slack-ruby-client'
require 'httparty'
require 'json'

Slack.configure do |config|
  config.token = ENV['SLACK_API_TOKEN']
end

# Slack Ruby client
$client = Slack::Web::Client.new


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
          "value": estimate,
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
          "text": estimate
        }
      },
      {
        "type": "actions",
        "elements": [
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

    body = { blocks: blocks }.to_json

    response = HTTParty.post(request_data['response_url'], body: body, channel: ENV['CHANNEL_OR_USER'], icon_emoji: icon, username: username )

    log(message: response)
    status 200
  when 'delete'
    ts = request_data['message']['ts']

    response = HTTParty.post(request_data['response_url'], body: { blocks: [] }.to_json, channel: ENV['CHANNEL_OR_USER'], icon_emoji: icon, username: username )

    log(message: response)
    status 200
  end
  # response = {
  #   payload: {
  #     type: "block_actions",
  #     team: {
  #       id: "T0DRJ2NQ4",
  #       domain: "socialmedialink"
  #     },
  #     user: {
  #       id: "UC8TB7B46",
  #       username: "luke.niedermyer",
  #       name: "luke.niedermyer",
  #       team_id: "T0DRJ2NQ4"
  #     },
  #     api_app_id: "AHQ9EDG1Z",
  #     token: "4tOjWhIZ2l4XL1uGdnu8RI1i",
  #     container: {
  #       type: "message",
  #       message_ts: "1555771432.000600",
  #       channel_id: "DC6RU5N56",
  #       is_ephemeral: false
  #     },
  #     trigger_id: "615919702295.13868090820.fe5580f5fc17bb55b930fef761f6d09a",
  #     channel: {
  #       id: "DC6RU5N56",
  #       name: "directmessage"
  #     },
  #     message: {
  #       type: "message",
  #       subtype: "bot_message",
  #       text: "Luke Niedermyer ********",
  #       ts: "1555771432.000600",
  #       bot_id: "BHQBH91FC",
  #       blocks: [
  #         {
  #           type: "context",
  #           block_id: "N4ul",
  #           elements: [
  #             { type: "mrkdwn", text: "*Author:* Luke Niedermyer", verbatim: false }
  #           ]
  #         },
  #         {
  #           type: "divider",
  #           block_id: "XLR/+"
  #         },
  #         {
  #           type: "section",
  #           block_id: "253",
  #           text: { type: "mrkdwn", text: "********", verbatim: false }
  #         },
  #         {
  #           type: "actions",
  #           block_id: "jl+s",
  #           elements: [
  #             {
  #               type: "button",
  #               action_id: "reveal",
  #               text: {
  #                 type: "plain_text",
  #                 text: "Reveal Estimate",
  #                 emoji: true
  #               },
  #               style: "primary",
  #               value: "reveal"
  #             },
  #             {
  #               type: "button",
  #               action_id: "delete",
  #               text: {
  #                 type: "plain_text",
  #                 text: "Delete",
  #                 emoji: true
  #               },
  #               style: "danger",
  #               value: "delete",
  #               confirm: {
  #                 title: { type: "plain_text", text: "Delete Luke Niedermyer 's Estimate?", emoji: true }, text: { type: "mrkdwn", text: "Are you sure that you want to delete this estimate?", verbatim: false }, confirm: { type: "plain_text", text: "Yes, delete it!", emoji: true }, "deny": { "type": "plain_text", text: "Nevermind, I' ll keep it", emoji: true }
  #               }
  #             }
  #           ]
  #         }
  #       ]
  #     },
  #     response_url: "https://hooks.slack.com/actions/T0DRJ2NQ4/602689458274/lVd1sCrwqQXrEeeaNGSTOgdJ",
  #     actions: [
  #       {
  #         action_id: "reveal",
  #         block_id: "jl+s",
  #         text: {
  #           type: "plain_text",
  #           text: "Reveal Estimate",
  #           emoji: true
  #         },
  #         value: "reveal",
  #         type: "button",
  #         style: "primary",
  #         action_ts: "1555771550.596900"
  #       }
  #     ]
  #   }
  # }
  status 200
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
