require 'sinatra'
require 'json'
# require 'byebug'
# require 'pry-byebug'

require_relative 'helpers/application_helper'
require_relative 'helpers/slack_helper'
require_relative 'helpers/circle_helper'

helpers ApplicationHelper
helpers SlackHelper
helpers CircleHelper

set :bind, '0.0.0.0'

get '/' do
  'PONG'
end

before '/' do
  if request.env['REQUEST_METHOD'] == "POST"
    secrets = load_secrets
    @users = secrets['users']
    @slack_token = secrets['slack_token']
    @slack_channels = secrets['slack_channels']
    if @users.nil? || @users.empty? || @slack_token.nil? || @slack_token.empty? || @slack_channels.nil? || @slack_channels.empty?
      log 'There is a problem with your secrets file.', nil
      halt 400
    end
  end
end

post '/' do
  response = JSON.parse request.body.read
  payload = response['payload']

  build_num = payload['build_num']
  vcs_login = payload['user']['login']
  status = payload['status']
  branch = payload['branch']
  has_slack_username = false
  slack_username =
    if @users[vcs_login]
      has_slack_username = true
      @users[vcs_login]
    else
      vcs_login
    end

  circle_details = build_circle_details payload

  slack_responses = []

  # Send via @slackbot only if the person who triggered the build has an associated Slack username in secrets.yml
  if has_slack_username
    slack_message = build_slack_message circle_details, slack_username
    slack_responses << send_slack_message(slack_message)
  end

  # Always send build notif to default_notify_channel specified in secrets.yml
  slack_message = build_slack_message circle_details, @slack_channels['default_notify_channel'], slack_username: slack_username
  slack_responses << send_slack_message(slack_message)

  # Only send failed build notifs for branches whose prefixes listed under important_branch_prefixes to
  # important_builds_notify_channel specified in secrets.yml
  if status != 'success' && is_important_branch(branch)
    options = { custom_text: "<!channel> The build for #{branch} by #{slack_username} failed." }
    slack_message = build_slack_message circle_details, @slack_channels['important_builds_notify_channel'], options
    slack_responses << send_slack_message(slack_message)
  end

  if !slack_responses.map(&:ok?).include? false
    status 200
  else
    slack_responses.each do |slack_response|
      if !slack_response.ok?
        log "Message sending failed with error: #{slack_response['error']}", build_num
      end
    end
    halt 400
  end
end
