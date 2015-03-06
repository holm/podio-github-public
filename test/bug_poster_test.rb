require 'bundler'
Bundler.require

require 'test/unit'
require 'podio_poster'

class BugPosterTest < Test::Unit::TestCase

  def test_set_status_to_fixed
    item_id = '13822'

    podio_poster = Podio::BugPoster.new # TODO: Supply app id and token for this to work
    item = podio_poster.get_item(item_id)
    comment = "Fixed a bug, fixes ##{item_id}"

    podio_poster.set_status_to_fixed(item, comment)
  end

end
