require 'bundler'
Bundler.require

require 'test/unit'
require 'webmock/minitest'


def fixture_file(filename)
  return '' if filename == ''
  file_path = File.expand_path(File.dirname(__FILE__) + '/fixtures/' + filename)
  File.read(file_path)
end
