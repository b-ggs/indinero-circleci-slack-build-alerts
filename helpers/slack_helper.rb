require 'httparty'

module SlackHelper
  SLACK_API_POST_MESSAGE_URL = 'https://slack.com/api/chat.postMessage'
  SUCCESS_COLOR = '#41AA58'
  FAIL_COLOR = '#D10C20'
  RUNNING_COLOR = '#66D3E4'
  SUCCESS_MESSAGE = 'Your build passed!'
  NON_SUCCESS_MESSAGE = 'There was a problem with your build.'

  def is_slack_user?(recipient)
    recipient[0] == '@'
  end

  def build_slack_message(build_details, slack_recipient, options = {})
    message =
      case build_details[:status]
      when 'success'
        options[:custom_success_message] || SUCCESS_MESSAGE
      else
        options[:custom_non_success_message] || NON_SUCCESS_MESSAGE
      end
    attachments = [
      {
        title: 'Build details',
        color: build_details[:status] == 'success' ? SUCCESS_COLOR : FAIL_COLOR,
        fields: [
          {
            title: 'Status',
            value: build_details[:status],
            short: true
          },
          {
            title: 'Branch',
            value: build_details[:branch],
            short: true
          },
          {
            title: 'Build Number',
            value: "<#{build_details[:build_url]}|##{build_details[:build_num]}> (triggered by #{build_details[:vcs_login]})",
            short: true
          },
          {
            title: 'Last Commit',
            value: "<#{build_details[:vcs_commit_url]}|#{build_details[:vcs_commit_hash]}> by #{build_details[:vcs_commit_login]}",
            short: true
          }
        ]
      }
    ]
    {
      token: @slack_token,
      channel: slack_recipient,
      text: message,
      link_names: true,
      attachments: attachments.to_json
    }
  end

  def send_slack_message(slack_message)
    resp = HTTParty.post(SLACK_API_POST_MESSAGE_URL, body: slack_message)
    if resp.ok?
      log LogHelper::DEBUG, "Successfully sent Slack message to #{slack_message[:channel]}"
    else
      log LogHelper::ERROR, "Failed to send Slack message with error: #{resp['error']}"
    end
  end
end
