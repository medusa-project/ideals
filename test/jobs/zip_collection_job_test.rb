require 'test_helper'

class ZipCollectionJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
    setup_opensearch
    Item.reindex_all
    refresh_opensearch
  end

  test "perform() updates the Task given to it" do
    collection      = collections(:southeast_collection1)
    download        = Download.create!(institution: institutions(:southeast))
    institution     = institutions(:southeast)
    user            = users(:southeast)
    request_context = RequestContext.new(client_ip:       "127.0.0.1",
                                         client_hostname: "example.org",
                                         user:            user,
                                         institution:     institution,
                                         role_limit:      Role::NO_LIMIT)
    task            = tasks(:pending)

    ZipCollectionJob.perform_now(collection:       collection,
                                 download:         download,
                                 institution:      institution,
                                 user:             user,
                                 request_context:  request_context,
                                 task:             task)

    task.reload
    assert_equal "ZipCollectionJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_equal ZipCollectionJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Generating")
  end

  test "perform() creates a zip file" do
    collection = collections(:southeast_collection1)
    download   = Download.create!(institution: institutions(:southeast))
    ZipCollectionJob.perform_now(collection: collection,
                                 download:   download)

    download.reload
    assert S3Client.instance.head_object(bucket: ObjectStore::BUCKET,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the zip file" do
    collection = collections(:southeast_collection1)
    download   = Download.create!(institution: institutions(:southeast))

    ZipCollectionJob.perform_now(collection: collection,
                                 download:   download)

    download.reload
    assert download.filename.match?(/\Acollection_\d+_[a-z\d]{16}.zip\z/)
  end

end
