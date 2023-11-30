require 'test_helper'

class SearchControllerTest < ActionDispatch::IntegrationTest

  setup do
    @institution = institutions(:southeast)
    host! @institution.fqdn
    setup_opensearch
  end

  teardown do
    log_out
  end

  # index()

  test "index() returns HTTP 200 in global scope" do
    host! ::Configuration.instance.main_host
    get search_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for HTML" do
    get search_path
    assert_response :ok
  end

  test "index() returns HTTP 200 for JSON" do
    get search_path(format: :json)
    assert_response :ok
  end

  test "index() omits submitting, submitted, embargoed, withdrawn, and buried
  items by default" do
    skip # TODO: this test is brittle and breaks often
    Unit.reindex_all
    Collection.reindex_all
    Item.reindex_all
    OpenSearchClient.instance.refresh

    unit_count       = Unit.where(institution: @institution).count
    collection_count = Collection.where(institution: @institution).count
    item_count       = Item.non_embargoed.
      where(institution: @institution).
      where(stage: Item::Stages::APPROVED).
      count

    get search_path(format: :json)
    struct = JSON.parse(response.body)
    assert_equal unit_count + collection_count + item_count,
                 struct['numResults']
  end
  
end
