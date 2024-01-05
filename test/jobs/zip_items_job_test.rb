require 'test_helper'

class ZipItemsJobTest < ActiveSupport::TestCase

  setup do
    setup_s3
  end

  test "perform() updates the Task given to it" do
    item_ids        = [items(:southeast_approved).id,
                       items(:southeast_multiple_bitstreams).id]
    download        = Download.create!(institution: institutions(:southeast))
    institution     = institutions(:southeast)
    user            = users(:southeast)
    request_context = RequestContext.new(client_ip:       "127.0.0.1",
                                         client_hostname: "example.org",
                                         user:            user,
                                         institution:     institution,
                                         role_limit:      Role::NO_LIMIT)
    task            = tasks(:pending)

    ZipItemsJob.perform_now(item_ids:         item_ids,
                            metadata_profile: institution.default_metadata_profile,
                            download:         download,
                            institution:      institution,
                            user:             user,
                            request_context:  request_context,
                            task:             task)

    task.reload
    assert_equal "ZipItemsJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_equal ZipItemsJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Generating")
  end

  test "perform() creates a zip file" do
    item_ids = [items(:southeast_approved).id,
                items(:southeast_multiple_bitstreams).id]
    download = Download.create!(institution: institutions(:southeast))
    ZipItemsJob.perform_now(item_ids:         item_ids,
                            metadata_profile: download.institution.default_metadata_profile,
                            download:         download)

    download.reload
    assert S3Client.instance.head_object(bucket: ObjectStore::BUCKET,
                                         key:    download.object_key).content_length > 0
  end

  test "perform() assigns a correct filename to the zip file" do
    item_ids = [items(:southeast_approved).id,
                items(:southeast_multiple_bitstreams).id]
    download = Download.create!(institution: institutions(:southeast))

    ZipItemsJob.perform_now(item_ids:         item_ids,
                            metadata_profile: download.institution.default_metadata_profile,
                            download:         download)

    download.reload
    assert download.filename.match?(/\Aitems-[a-z\d]{16}.zip\z/)
  end

end
