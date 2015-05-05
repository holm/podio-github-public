require 'sinatra/base'
require "#{File.expand_path("../", __FILE__)}/commit_parser"
require "#{File.expand_path("../", __FILE__)}/podio_poster"

class WebHookServer < Sinatra::Base
  # configure do
  #   set :raise_errors, true
  #   set :show_exceptions, false
  # end

  get '/' do
    "It works"
  end

  post '/hook' do
    return "Missing app_id or app_token" if params[:app_id].blank? || params[:app_token].blank?

    parsed_commits = CommitParser.parse_payload(params[:payload])
    if parsed_commits
      parsed_commits.each do |commit|
        if commit[:bug]
          podio_poster = Podio::BugPoster.new(params[:app_id].to_i, params[:app_token])
          podio_poster.process([commit[:bug]])
        end

        if commit[:task]
          podio_poster = Podio::TaskPoster.new
          podio_poster.process([commit[:task]])
        end

        if commit[:story]
          podio_poster = Podio::StoryPoster.new
          podio_poster.process([commit[:story]])
        end
      end
    end

    "Thanks!"
  end
end
