module CommitParser
  CLOSE_COMMANDS = %w(close closed closes fix fixed fixes)
  REF_COMMANDS   = %w(references refs addresses re see)

  def self.parse_payload(payload)
    commit_log = Yajl::Parser.parse(payload)

    # only look at commits to master
    return if commit_log['ref'] != 'refs/heads/master'

    commit_log['commits'].map { |commit| parse_commit(commit) }
  end

  def self.parse_commit(commit)
    parsed_item_groups = extract_items_with_actions(commit['message'])
    parsed_item_groups.each do |group, items|
      items.each do |item, data|
        data[:comment] = format_comment(commit)
      end
    end

    parsed_item_groups
  end

  def self.format_comment(commit)
    id      = commit['id'][0..5]
    url     = commit['url']
    author  = commit['author']['name']
    message = commit['message']

    "(#{author}, in [[#{id}]](#{url})) #{message}"
  end

  def self.extract_items_with_actions(message, default_prefix = :bug)
    ticket_prefix = '(?:#|(?:(bug|task|story)?)[: ]?)'
    ticket_reference = ticket_prefix + '[0-9]+'
    # ticket_command = /([A-Za-z]*)\s*.?\s*(#{ticket_reference}(?:(?:[, &]*|[ ]?and[ ]?)#{ticket_reference})*)/
    all_commands = (CLOSE_COMMANDS + REF_COMMANDS).join('|')
    ticket_command = /(#{all_commands})\s*.?\s*(#{ticket_reference}(?:(?:[, &]*|[ ]?and[ ]?)#{ticket_reference})*)/i

    ticket_re = /#{ticket_prefix}([0-9]+)/

    parsed_items = {}
    cmd_groups = message.scan(ticket_command)
    cmd_groups.each do |cmd, ticket_ids|
      action = nil
      action = :cmd_close if CLOSE_COMMANDS.include?(cmd.downcase)
      action = :cmd_ref if REF_COMMANDS.include?(cmd.downcase)

      next if action.nil?

      ticket_ids.scan(ticket_re).each do |prefix, id|
        prefix ||= default_prefix
        parsed_items[prefix.to_sym] ||= {}
        parsed_items[prefix.to_sym][id.to_i] = {:action => action}
      end
    end

    parsed_items
  end
end
