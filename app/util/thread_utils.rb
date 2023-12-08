# frozen_string_literal: true

class ThreadUtils

  ##
  # @param items [Enumerable<Object>] Full result set with no limit/offset
  #              applied.
  # @param num_threads [Integer]
  # @param print_progress [Boolean] Whether to print progress to stdout.
  # @param rescue_errors [Boolean] Whether to rescue errors.
  # @param block [Block] Block to invoke on each item.
  #
  def self.process_in_parallel(items,
                               num_threads:    2,
                               print_progress: false,
                               rescue_errors:  false,
                               &block)
    # Divide the total number of items into num_threads segments, and have
    # each thread work on a segment.
    total_count      = items.count
    return if total_count < 1
    mutex            = Mutex.new
    threads          = Set.new
    progress         = Progress.new(total_count)
    item_index       = 0
    num_threads      = [num_threads, total_count].min
    items_per_thread = (total_count / num_threads.to_f).ceil
    return if items_per_thread < 1
    proceed          = true # if one thread errors, stop all other threads

    num_threads.times do |thread_num|
      threads << Thread.new do
        batch_size  = [1000, items_per_thread].min
        num_batches = (items_per_thread / batch_size.to_f).ceil
        num_batches.times do |batch_index|
          break unless proceed
          batch_offset = batch_index * batch_size
          q_offset     = thread_num * items_per_thread + batch_offset
          q_limit      = [batch_size, items_per_thread - batch_offset].min
          batch        = items.respond_to?(:offset) ?
                           items.offset(q_offset).limit(q_limit) :
                           items[q_offset..(q_offset + q_limit)]
          batch.each do |item|
            break unless proceed
            if rescue_errors
              block.call(item) rescue nil
            else
              begin
                block.call(item)
              rescue => e
                mutex.synchronize { proceed = false }
                raise e
              end
            end
            mutex.synchronize do
              item_index += 1
              progress.report(item_index, "Processing") if print_progress
            end
          end
        end
      end
    end
    threads.each(&:join)
    puts "" if print_progress
  end

  ##
  # @param proc [Proc]
  #
  def self.use_other_connection(proc)
    # In test, ActiveRecord does not use a different database connection across
    # threads, which can cause deadlocks
    if Rails.env.test?
      proc.call
    else
      Thread.new do
        self.class.connection_pool.with_connection do
          proc.call
        end
      end.join
    end
  end

end
