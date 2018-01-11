require 'yaml'

module ApplicationHelper
  def load_secrets
    YAML.load_file File.expand_path('../../secrets.yml', __FILE__)
  end

  def load_last_30_finished_build_nums
    resp = []
    File.open File.expand_path('../../last_30_finished_build_nums.txt', __FILE__), 'a+' do |f|
      f.each_line do |line|
        resp.push line.chomp.to_i
      end
    end
    resp
  end

  def update_last_30_finished_build_nums(data)
    data = data.last(30)
    File.open File.expand_path('../../last_30_finished_build_nums.txt', __FILE__), 'w+' do |f|
      data.each do |datum|
        f.puts datum
      end
    end
  end

  def load_failed_important_branches
    resp = ''
    File.open File.expand_path('../../failed_important_branches.txt', __FILE__), 'a+' do |f|
      f.each_line do |line|
        resp << line.chomp
      end
    end
    resp.split(',')
  end

  def update_failed_important_branches(data, append = false)
    failed_important_branches = data
    if append
      failed_important_branches = load_failed_important_branches
      failed_important_branches << data
    end
    failed_important_branches = failed_important_branches.compact.uniq.join(',')
    File.open File.expand_path('../../failed_important_branches.txt', __FILE__), 'w+' do |f|
      f.puts failed_important_branches
    end
  end

  def is_important_branch(branch_name)
    important_branch_prefixes = load_secrets['important_branch_prefixes']
    regex = /^(#{important_branch_prefixes.join('|')})\/.+/i
    branch_name =~ regex || branch_name == 'circleci-slack-user-specifc-build-alerts-test'
  end
end
