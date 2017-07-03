require 'httparty'

SLACK_API_POST_MESSAGE_URL = 'https://slack.com/api/chat.postMessage'

module SlackHelper
  def build_slack_message(build_details, slack_recipient, options = {})
    user = options[:slack_username] ? options[:slack_username] << '\'s' : 'your'
    default_text =
      if build_details[:status] == 'success'
        "#{user.capitalize} build passed!"
      else
        "There was a problem with #{user} build."
      end
    text = options[:custom_text] || default_text
    attachments = [
      {
        title: 'Build details',
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
      text: text,
      link_names: true,
      attachments: attachments.to_json
    }
  end

  def send_slack_message(slack_message)
    HTTParty.post(SLACK_API_POST_MESSAGE_URL, body: slack_message)
  end
end
