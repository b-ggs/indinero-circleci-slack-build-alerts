module LogHelper
  INFO = 'INFO'
  ERROR = 'ERROR'
  DEBUG = 'DEBUG'

  def format_message(log_tag, message)
    resp = ''
    resp << Time.now.to_s << ' - '
    resp << log_tag << ' - '
    resp << message
    resp
  end

  def log(log_tag, message)
    message = format_message log_tag, message
    File.open File.expand_path('../../app.log', __FILE__), 'a+' do |f|
      f.puts message
    end
    $stderr.puts message
  end
end
