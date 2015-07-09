require 'sinatra/base'
require "#{File.expand_path("../", __FILE__)}/commit_parser"
require "#{File.expand_path("../", __FILE__)}/podio_poster"

class WebHookServer < Sinatra::Base

  get '/' do
    "It works"
  end

  post '/hook' do
    return "Missing app_id or app_token" if params[:app_id].blank? || params[:app_token].blank?

    parsed_commits = CommitParser.parse_payload(params[:payload])
    if parsed_commits
      parsed_commits.each do |commit|
        podio_poster = Podio::Poster.new(params[:app_id].to_i, params[:app_token], params[:field], params[:value])
        podio_poster.process([commit[:bug]])
      end
    end

    "Thanks!"
  end
end
