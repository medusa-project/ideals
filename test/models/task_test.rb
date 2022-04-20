require "test_helper"

class TaskTest < ActiveSupport::TestCase

  # initialize()

  test "new instances have correct attributes" do
    task = Task.new
    assert_equal Task::Status::PENDING, task.status
    assert_nil task.started_at
    assert_nil task.stopped_at
    assert_nil task.backtrace
    assert_nil task.detail
    assert !task.indeterminate
    assert_equal 0, task.percent_complete
  end

  # estimated_completion()

  test "estimated_completion() returns nil for a pending task" do
    task = tasks(:pending)
    assert_nil task.estimated_completion
  end

  test "estimated_completion() returns an accurate figure for a running task" do
    task = tasks(:running)
    assert task.estimated_completion > Time.now
    assert task.estimated_completion < Time.now + 2.hours
  end

  test "estimated_completion() returns an accurate figure for a paused task" do
    task = tasks(:paused)
    assert task.estimated_completion > Time.now
    assert task.estimated_completion < Time.now + 2.hours
  end

  test "estimated_completion() returns nil for a stopped task" do
    task = tasks(:stopped)
    assert_nil task.estimated_completion
  end

  test "estimated_completion() returns nil for a succeeded task" do
    task = tasks(:succeeded)
    assert_nil task.estimated_completion
  end

  test "estimated_completion() returns nil for a failed task" do
    task = tasks(:failed)
    assert_nil task.estimated_completion
  end

  # fail()

  test "fail() sets the status to failed" do
    task = tasks(:running)
    task.fail
    assert_equal Task::Status::FAILED, task.status
  end

  test "fail() sets stopped_at" do
    task = tasks(:running)
    task.fail
    assert_not_nil task.stopped_at
  end

  test "fail() sets the detail and backtrace, if provided" do
    task      = tasks(:running)
    detail    = "Oops"
    backtrace = "This is a backtrace"
    task.fail(detail: detail, backtrace: backtrace)
    assert_equal detail, task.detail
    assert_equal backtrace, task.backtrace
  end

  # failed?()

  test "failed?() returns true for a failed task" do
    task = tasks(:failed)
    assert task.failed?
  end

  test "failed?() returns false for a non-failed task" do
    task = tasks(:succeeded)
    assert !task.failed?
  end

  # pause()

  test "pause() sets the status to paused" do
    task = tasks(:paused)
    task.pause
    assert_equal Task::Status::PAUSED, task.status
  end

  # paused?()

  test "paused?() returns true for a paused task" do
    task = tasks(:paused)
    assert task.paused?
  end

  test "paused?() returns false for a non-paused task" do
    task = tasks(:running)
    assert !task.paused?
  end

  # percent_complete

  test "percent_complete is clamped between 0 and 1 on save" do
    task = tasks(:running)
    task.update(percent_complete: -0.5)
    assert_equal 0, task.percent_complete
    task.update(percent_complete: 1.5)
    assert_equal 1, task.percent_complete
  end

  # progress()

  test "progress() updates percent_complete" do
    task = tasks(:running)
    task.progress(0.85)
    assert_equal 0.85, task.percent_complete
  end

  test "progress() sets started_at when the argument is greater than 1 and
  started_at is blank" do
    task = tasks(:pending)
    task.progress(0.85)
    assert_not_nil task.started_at
  end

  test "progress() sets the status to running when the argument is less than 1" do
    task = tasks(:pending)
    task.progress(0.85)
    assert_equal Task::Status::RUNNING, task.status
  end

  test "progress() succeeds the task when the argument is 1" do
    task = tasks(:pending)
    task.progress(1)
    assert_equal Task::Status::SUCCEEDED, task.status
    assert_not_nil task.stopped_at
  end

  # running?()

  test "running?() returns true for a running task" do
    task = tasks(:running)
    assert task.running?
  end

  test "running?() returns false for a non-running task" do
    task = tasks(:succeeded)
    assert !task.running?
  end

  # stop()

  test "stop() sets the status to stopped" do
    task = tasks(:running)
    task.stop
    assert_equal Task::Status::STOPPED, task.status
  end

  test "stop() sets stopped_at" do
    task = tasks(:running)
    task.stop
    assert_not_nil task.stopped_at
  end

  # stopped?()

  test "stopped?() returns true for a stopped task" do
    task = tasks(:stopped)
    assert task.stopped?
    task = tasks(:succeeded)
    assert task.stopped?
    task = tasks(:failed)
    assert task.stopped?
  end

  test "stopped?() returns true for a succeeded task" do
    task = tasks(:succeeded)
    assert task.stopped?
  end

  test "stopped?() returns true for a failed task" do
    task = tasks(:failed)
    assert task.stopped?
  end

  test "stopped?() returns false for a non-stopped task" do
    task = tasks(:running)
    assert !task.stopped?
  end

  # succeed()

  test "succeed() sets the status to succeeded" do
    task = tasks(:running)
    task.succeed
    assert_equal Task::Status::SUCCEEDED, task.status
  end

  test "succeed() sets percent_complete to 1" do
    task = tasks(:running)
    task.succeed
    assert_equal 1, task.percent_complete
  end

  test "succeed() sets stopped_at" do
    task = tasks(:running)
    task.succeed
    assert_not_nil task.stopped_at
  end

  test "succeed() updates status_text, if provided" do
    task = tasks(:running)
    status_text = "new status text"
    task.succeed(status_text: status_text)
    assert_equal status_text, task.status_text
  end

  # succeeded?()

  test "succeeded?() returns true for a succeeded task" do
    task = tasks(:succeeded)
    assert task.succeeded?
  end

  test "succeeded?() returns false for a non-succeeded task" do
    task = tasks(:failed)
    assert !task.succeeded?
  end

end
