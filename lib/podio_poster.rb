module Podio
  class BasePoster

    def setup_client(app_id, app_token)
      podio_client = Podio::Client.new({
        :api_key => ENV["PODIO_CLIENT_ID"],
        :api_secret => ENV["PODIO_CLIENT_SECRET"]
      })
      puts "Authenticating with #{app_id} and #{app_token}"
      podio_client.authenticate_with_app(app_id, app_token)

      podio_client
    end

    def process(commits)
      commits.each do |commit|
        next if commit.blank?

        commit.each do |item_id, data|
          update_item_on_podio(item_id, data[:action], data[:comment])
        end
      end
    end

    def update_item_on_podio(item_id, cmd, comment)
      item = get_item(item_id)
      return if item.nil?
      return unless [:cmd_close, :cmd_ref].include?(cmd)

      add_comment_to_item(item, comment)
      set_status_to_fixed(item, comment) if cmd == :cmd_close
    end

    def add_comment_to_item(item, comment)
      @podio_client.connection.post do |req|
        req.url "/comment/item/#{item['item_id']}"
        req.body = {:value => comment}
      end
    end

    def get_item(ticket_id)
      @podio_client.connection.get("/app/#{@app_id}/item/#{ticket_id}").body
    rescue Podio::NotFoundError
      # try with global item_id
      @podio_client.connection.get("/item/#{ticket_id}").body
    rescue Podio::AuthorizationError, Podio::GoneError, Podio::NotFoundError
      nil
    end

    protected

    def find_field(item, type, identifier)
      item['fields'].find { |field| field['type'] == type && (field['external_id'] == identifier || field['config']['label'].casecmp(identifier).zero?) && field['status'] =='active' }
    end
  end

  class BugPoster < BasePoster
    def initialize(app_id, app_token)
      @app_id = app_id
      @podio_client = setup_client(app_id, app_token)
    end
    
    def set_status_to_fixed(item, comment)
      status_field = find_field(item, 'category', 'status')
      return if status_field.nil?

      fields = []

      option_id = status_field['config']['settings']['options'].find { |option| option['text'] == 'Fixed' }['id']
      fields << {:external_id => 'status', :values => [{'value' => option_id}]}

      @podio_client.connection.put do |req|
        req.url "/item/#{item['item_id']}/value"
        req.body = fields
      end
    end

  end

  class TaskPoster < BasePoster
    APP_ID = 1234
    APP_TOKEN = 'REDACTED'

    def initialize
      @app_id = APP_ID
      @podio_client = setup_client(APP_ID, APP_TOKEN)
    end

    def set_status_to_fixed(item, comment)
      status_field = item['fields'].find { |field| field['external_id'] == 'status' && field['status'] =='active' }
      return if status_field.nil?

      fields = []

      option_id = status_field['config']['settings']['options'].find { |option| option['text'] == 'Dev done' }['id']
      fields << {:external_id => 'status', :values => [{'value' => option_id}]}

      update_time_spent(comment, fields)

      @podio_client.connection.put do |req|
        req.url "/item/#{item['item_id']}/value"
        req.body = fields
      end
    end

    def update_time_spent(comment, fields)
      matches = comment.match(/spent (\d+)(h|m)(?:(\d+)(m))?/i)
      return unless matches

      time_intervals = matches.to_a.compact
      time_intervals.shift

      total_seconds = 0

      time_intervals.each_slice(2) do |number, abbreviation|
        number = number.to_i
        if number > 0
          case abbreviation
          when 'h'
            total_seconds += number*3600
          when 'm'
            total_seconds += number*60
          end
        end
      end

      if total_seconds > 0
        fields <<  { :external_id => 'time-left', :values => [{'value' => total_seconds}] }
      end
    end

  end

  class StoryPoster < BasePoster
    APP_ID = 1234
    APP_TOKEN = 'REDACTED'

    def initialize
      @app_id = APP_ID
      @podio_client = setup_client(APP_ID, APP_TOKEN)
    end

    def set_status_to_fixed(item, comment)
      status_field = item['fields'].find { |field| field['external_id'] == 'status' && field['status'] =='active' }
      return if status_field.nil?

      fields = []

      option_id = status_field['config']['settings']['options'].find { |option| option['text'] == 'In PO Review' }['id']
      fields << {:external_id => 'status', :values => [{'value' => option_id}]}

      @podio_client.connection.put do |req|
        req.url "/item/#{item['item_id']}/value"
        req.body = fields
      end
    end

  end

end
