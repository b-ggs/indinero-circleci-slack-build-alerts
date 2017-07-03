require 'yaml'
require 'logger'

module ApplicationHelper 
  def load_secrets
    YAML.load_file(File.expand_path '../../secrets.yml', __FILE__)
  end

  def format_message(message, build_num)
    "#{Time.now.to_s} - Build #{build_num} - #{message}"
  end

  def log(message, build_num)
    message = format_message message, build_num
    File.open 'app.log', 'a+' do |f|
      f.puts message
    end
    $stderr.puts message
  end

  def is_important_branch(branch_name)
    important_branch_prefixes = load_secrets['important_branch_prefixes']
    regex = /^(#{important_branch_prefixes.join('|')})\/.+/i
    branch_name =~ regex || branch_name == 'circleci-slack-user-specifc-build-alerts-test'
  end
end
