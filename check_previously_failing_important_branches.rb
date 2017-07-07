# require 'byebug'
# require 'pry-byebug'

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
@circle_token = secrets['circle_token']
@slack_channels = secrets['slack_channels']

log LogHelper::DEBUG, 'Checking previously failed important branches...'

failed_important_branches = load_failed_important_branches

log LogHelper::DEBUG, "Previously failed important branches: #{failed_important_branches}"

failed_important_branch_builds = failed_important_branches.map do |branch|
  last_build = get_last_build_for_branch branch
  if last_build['outcome'] == 'success'
    nil
  else
    last_build
  end
end

log LogHelper::DEBUG, "Still failing important branches: #{failed_important_branches}"

failed_important_branch_builds.each do |build|
  branch = build['branch']
  vcs_login = build['user']['login']
  slack_username = @users[vcs_login] || vcs_login

  circle_details = build_circle_details build

  channel = @slack_channels['important_builds_notify_channel']
  options = {
    custom_non_success_message: "@channel The build for #{branch} by #{slack_username} is still failing!"
  }
  slack_message = build_slack_message circle_details, channel, options
  send_slack_message slack_message
end

update_failed_important_branches failed_important_branches

log LogHelper::DEBUG, 'End checking previously failed important branches'
