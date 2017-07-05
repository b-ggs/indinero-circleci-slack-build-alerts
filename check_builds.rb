require 'byebug'
require 'pry-byebug'

require_relative 'helpers/application_helper'
require_relative 'helpers/slack_helper'
require_relative 'helpers/circle_helper'
require_relative 'helpers/log_helper'

include ApplicationHelper
include CircleHelper
include SlackHelper
include LogHelper

secrets = load_secrets
@users = secrets['users']
@slack_token = secrets['slack_token']
@slack_channels = secrets['slack_channels']
@circle_token = secrets['circle_token']

log LogHelper::DEBUG, 'Checking for new builds...'

last_checked_build_num = load_last_checked_build_num

latest_builds = get_latest_builds.delete_if do |build|
  last_checked_build_num >= build['build_num'].to_i
end

log LogHelper::DEBUG, "Found #{latest_builds.count} new builds..."

latest_builds.each do |build|
  build_num = build['build_num']
  vcs_login = build['user']['login']
  status = build['status']
  branch = build['branch']
  slack_username = @users[vcs_login] || vcs_login

  circle_details = build_circle_details build

  # Send via @slackbot only if the person who triggered the build has an associated Slack username in secrets.yml
  if is_slack_user? slack_username
    slack_message = build_slack_message circle_details, slack_username
    send_slack_message slack_message
  end

  # Always send build notif to default_notify_channel specified in secrets.yml
  channel = @slack_channels['default_notify_channel']
  options = {
    custom_success_message: "#{slack_username}'s build passed!",
    custom_non_success_message: "There was a problem with #{slack_username}'s build."
  }
  slack_message = build_slack_message circle_details, channel, options
  send_slack_message slack_message

  # Only send failed build notifs for branches whose prefixes listed under important_branch_prefixes to
  # important_builds_notify_channel specified in secrets.yml
  if status != 'success' && is_important_branch(branch)
    update_failed_important_branches branch, true
    channel = @slack_channels['important_builds_notify_channel']
    options = { custom_non_success_message: "@channel The build for #{branch} by #{slack_username} failed." }
    slack_message = build_slack_message circle_details, channel, options
    send_slack_message slack_message
  end
end

if !latest_builds.empty?
  update_last_checked_build_num latest_builds.first['build_num']
end

log LogHelper::DEBUG, 'End checking for new builds'
