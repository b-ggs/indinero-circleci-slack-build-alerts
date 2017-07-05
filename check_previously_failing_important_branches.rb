require 'httparty'
# require 'byebug'
# require 'pry-byebug'

require_relative 'helpers/application_helper'
require_relative 'helpers/slack_helper'
require_relative 'helpers/log_helper'

include ApplicationHelper
include SlackHelper
include LogHelper

def get_last_build_for_branch(branch)
  url = "https://circleci.com/api/v1.1/project/github/jessicamah/indinero/tree/#{branch}?circle-token=#{@circle_token}"
  resp = JSON.parse HTTParty.get url
  resp.last
end

log 'Checking previously failed builds...', nil

secrets = load_secrets
@users = secrets['users']
@slack_token = secrets['slack_token']
@circle_token = secrets['circle_token']
@slack_channels = secrets['slack_channels']
failed_builds = load_failed_builds

log "Previously failed builds: #{failed_builds}", nil

failed_builds = failed_builds.map do |branch|
  last_build = get_last_build_for_branch branch
  if last_build['status'] == 'success'
    nil
  else
    last_build
  end
end.compact

failed_builds_branches = failed_builds.map { |build| build['branch'] }
log "Builds still failing: #{failed_builds_branches}", nil
update_failed_builds failed_builds_branches

slack_message_fields = 
  failed_builds.map do |failed_build|
    vcs_login = failed_build['user']['login']
    slack_username = @users[vcs_login] || vcs_login
    {
      title: failed_build['branch'],
      value: "Last triggered by #{slack_username}"
    }
  end

if !failed_builds.empty?
  slack_message = {
    token: @slack_token,
    channel: @slack_channels['important_builds_notify_channel'],
    text: '@channel These builds are still failing!',
    link_names: true,
    attachments: [
      {
        title: 'Failing branches:',
        fields: slack_message_fields
      }
    ].to_json
  }

  slack_response = send_slack_message slack_message

  if !slack_response.ok?
    log "Message sending failed with error: #{slack_response['error']}", build_num
  end
end
