require 'yaml'

module ApplicationHelper 
  def load_secrets
    YAML.load_file File.expand_path('../../secrets.yml', __FILE__)
  end

  def load_last_checked_build_num
    resp = ''
    File.open File.expand_path('../../last_checked_build.txt', __FILE__), 'a+' do |f|
      f.each_line do |line|
        resp << line.chomp
      end
    end
    resp = resp.chomp || 0
    resp.to_i
  end

  def update_last_checked_build_num(data)
    File.open File.expand_path('../../last_checked_build.txt', __FILE__), 'w+' do |f|
      f.puts data
    end
  end

  def load_failed_builds
    resp = ''
    File.open File.expand_path('../../failed_builds.txt', __FILE__), 'a+' do |f|
      f.each_line do |line|
        resp << line.chomp
      end
    end
    resp.split(',')
  end

  def update_failed_builds(data, append = false)
    failed_builds = data
    if append
      failed_builds = load_failed_builds
      failed_builds << data
    end
    failed_builds = failed_builds.compact.uniq.join(',')
    File.open File.expand_path('../../failed_builds.txt', __FILE__), 'w+' do |f|
      f.puts failed_builds
    end
  end

  def is_important_branch(branch_name)
    important_branch_prefixes = load_secrets['important_branch_prefixes']
    regex = /^(#{important_branch_prefixes.join('|')})\/.+/i
    branch_name =~ regex || branch_name == 'circleci-slack-user-specifc-build-alerts-test'
  end
end
