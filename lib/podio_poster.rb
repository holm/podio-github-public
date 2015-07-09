module Podio
  class Poster

    def initialize(app_id, app_token, field=nil, value=nil)
      @app_id = app_id
      @field = field || 'status'
      @value = value || 'Fixed'
      @podio_client = setup_client(app_id, app_token)
    end

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

    def get_item(ticket_id)
      @podio_client.connection.get("/app/#{@app_id}/item/#{ticket_id}").body
    rescue Podio::NotFoundError
      # try with global item_id
      @podio_client.connection.get("/item/#{ticket_id}").body
    rescue Podio::AuthorizationError, Podio::GoneError, Podio::NotFoundError
      nil
    end
    
    def set_category(item)
      cat_field = find_field(item, 'category', @field)
      return if cat_field.nil?

      fields = []

      option_id = cat_field['config']['settings']['options'].find { |option| option['text'] == @value }['id']
      fields << {:external_id => cat_field['external_id'], :values => [{'value' => option_id}]}

      @podio_client.connection.put do |req|
        req.url "/item/#{item['item_id']}/value"
        req.body = fields
      end
    end

    protected

    def update_item_on_podio(item_id, cmd, comment)
      item = get_item(item_id)
      return if item.nil?
      return unless [:cmd_close, :cmd_ref].include?(cmd)

      add_comment_to_item(item, comment)
      set_category(item) if cmd == :cmd_close
    end

    def add_comment_to_item(item, comment)
      @podio_client.connection.post do |req|
        req.url "/comment/item/#{item['item_id']}"
        req.body = {:value => comment}
      end
    end

    def find_field(item, type, identifier)
      item['fields'].find { |field| field['type'] == type && (field['external_id'] == identifier || field['config']['label'].casecmp(identifier).zero?) && field['status'] =='active' }
    end
  end

end
