require 'httparty'

module CircleHelper
  CIRCLECI_PROJECT_BASE_URL = 'https://circleci.com/api/v1.1/project/github/jessicamah/indinero'

  def get_latest_builds(limit = 20)
    options = {
      'circle-token' => @circle_token,
      'limit' => limit,
      'filter' => 'completed'
    }
    resp = HTTParty.get CIRCLECI_PROJECT_BASE_URL, query: options
    if resp.ok?
      log LogHelper::DEBUG, 'Successfully retrieved latest CircleCI builds'
    else
      log LogHelper::ERROR, "Failed to retrieve latest CircleCI builds with error: #{resp['error']}"
      resp = []
    end
    JSON.parse resp
  end

  def build_circle_details(payload)
    default_commit_details = {
      'committer_login' => 'unknown',
      'commit' => 'Unknown',
      'commit_url' => payload['vcs_url'],
      'subject' => 'Unknown'
    }
    log LogHelper::INFO, "Build #{payload['build_num']} by #{payload['user']['login']}: #{payload['status']}"
    last_commit = payload['all_commit_details'].last || default_commit_details
    {
      status: payload['status'],
      build_num: payload['build_num'],
      build_url: payload['build_url'],
      branch: payload['branch'],
      build_time_millis: payload['build_time_millis'],
      vcs_login: payload['user']['login'],
      vcs_commit_login: last_commit['committer_login'],
      vcs_commit_hash: last_commit['commit'],
      vcs_commit_url: last_commit['commit_url'],
      vcs_commit_message: last_commit['subject']
    }
  end
end
