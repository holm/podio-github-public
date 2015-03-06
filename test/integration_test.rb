require 'test_helper'
require 'rack/test'
require 'server'

class IntegrationTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    WebHookServer
  end

  def test_needs_app_id_and_app_token
    post '/hook'
    assert_equal 'Missing app_id or app_token', last_response.body
  end

  def test_should_parse_push_from_github
    # auth Podio client
    stub_request(:post, 'https://api.podio.com/oauth/token').
      with(:body => {'app_id' => '42', 'app_token' => 'APP_TOKEN', 'client_id' => true, 'client_secret' => true, 'grant_type'=>'app'}).
      to_return(:body => "access_token=lala")

    # set bug #60097 to Fixed
    stub_request(:get, "https://api.podio.com/app/42/item/60097").to_return(:status => 404)
    stub_request(:get, 'https://api.podio.com/item/60097').to_return(:status => 200)
    stub_request(:post, "https://api.podio.com/comment/item/60097").to_return(:status => 200)
    stub_request(:put, "https://api.podio.com/item/60097/value").with(:body => /Fixed/).to_return(:status => 200)

    # only comment on #60095
    stub_request(:get, "https://api.podio.com/app/42/item/60095").to_return(:status => 404)
    stub_request(:get, 'https://api.podio.com/item/60095').to_return(:status => 200)
    stub_request(:post, "https://api.podio.com/comment/item/60095").to_return(:status => 200)

    post '/hook?app_id=42&app_token=APP_TOKEN', :payload => fixture_file('sample_payload.json')

    assert last_response.ok?
  end

  def test_should_parse_push_from_github_not_on_master
    post '/hook?app_id=42&app_token=APP_TOKEN', :payload => fixture_file('branch_payload.json')

    assert last_response.ok?
  end
end
