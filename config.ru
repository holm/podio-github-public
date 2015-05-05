require 'bundler'
Bundler.require

missing = %w(PODIO_CLIENT_ID PODIO_CLIENT_SECRET).reject { |k| ENV.include?(k) }
if missing.present?
  abort "Missing from ENV: #{missing.join ', '}"
end

require "#{File.expand_path("../", __FILE__)}/lib/server"

$stdout.sync = true

run WebHookServer
