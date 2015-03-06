require 'bundler'
Bundler.require

require 'test/unit'
require 'podio_poster'
#require 'rack/test'
#require 'server'

class TaskPosterTest < Test::Unit::TestCase

  #include Rack::Test::Methods

  #def app
  #  WebHookServer
  #end

  # Not stubbed, run with care
  # def test_close
  #  podio_poster = Podio::TaskPoster.new
  #  assert podio_poster.process([{1 => {:action => :cmd_close, :comment => 'Closing now'}}])
  # end

  # def test_should_parse_push_from_github
  #   post '/hook?app_id=42&app_token=APP_TOKEN', :payload => fixture_file('sample_payload.json')
  #   assert last_response.ok?
  # end

  def test_update_time_spent
    [
      ["Did this, spent 2h45m", 9900],
      ["Spent 1h", 3600],
      ["Did that. Spent 5m", 300],
      ["Did this, spent no time at all", nil],
      ["Did this, spent", nil],
      ["Spent money", nil]
    ].each do |input, output|
      podio_poster = Podio::TaskPoster.new
      fields = []
      podio_poster.update_time_spent(input, fields)
      value = fields.first[:values].first['value'] if fields.first
      assert_equal output, value
    end
  end

  # def fixture_file(filename)
  #   return '' if filename == ''
  #   file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
  #   File.read(file_path)
  # end

end
