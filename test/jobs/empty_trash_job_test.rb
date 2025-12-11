require 'test_helper'

class EmptyTrashJobTest < ActiveSupport::TestCase

  test "perform() updates the Task given to it" do
    institution = institutions(:southeast)
    user        = users(:southeast)
    task        = tasks(:pending)

    EmptyTrashJob.perform_now(institution: institution,
                              user:        user,
                              task:        task)

    task.reload
    assert_equal "EmptyTrashJob", task.name
    assert_equal institution, task.institution
    assert_equal user, task.user
    assert !task.indeterminate
    assert_equal EmptyTrashJob::QUEUE.to_s, task.queue
    assert_not_empty task.job_id
    assert_not_nil task.started_at
    assert task.status_text.start_with?("Emptying")
  end

  test "perform() empties an institution's trash" do
    institution = institutions(:southeast)
    count = Item.where(institution: institution,
                       stage:       Item::Stages::BURIED).count
    assert count > 0

    EmptyTrashJob.perform_now(institution: institution)

    count = Item.where(institution: institution,
                       stage:       Item::Stages::BURIED).count
    assert_equal 0, count
  end

  test "perform() does not empty any other institutions' trashes" do
    institution = institutions(:southwest)

    EmptyTrashJob.perform_now(institution: institution)

    count = Item.where(stage: Item::Stages::BURIED).count
    assert count > 0
  end

end
