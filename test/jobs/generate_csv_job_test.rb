require 'test_helper'

class GenerateCsvJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() updates the Task given to it" do
    collection  = collections(:southeast_collection1)
    download    = Download.create!(institution: institutions(:southeast))
    institution = institutions(:southeast)
    user        = users(:southeast)
    task        = tasks(:pending)

    GenerateCsvJob.perform_now(collection:  collection,
                               download:    download,
                               institution: institution,
                               user:        user,
                               task:        task)

    task.reload
    assert_equal "GenerateCsvJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert task.indeterminate
    assert_equal GenerateCsvJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Generating")
  end

  test "perform() creates a CSV file" do
    collection = collections(:southeast_collection1)
    download   = Download.create!(institution: institutions(:southeast))
    GenerateCsvJob.perform_now(collection: collection,
                               download:   download)

    download.reload
    assert S3Client.instance.head_object(bucket: ObjectStore::BUCKET,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the CSV file" do
    collection = collections(:southeast_collection1)
    download   = Download.create!(institution: institutions(:southeast))

    GenerateCsvJob.perform_now(collection: collection,
                                 download:   download)

    download.reload
    assert download.filename.match?(/\Acollection_\d+_items.csv\z/)
  end

end
