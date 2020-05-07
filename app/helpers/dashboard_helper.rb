module DashboardHelper

  ##
  # @return [ToDoList] The {ApplicationController#current_user current user}'s
  #                    to-do list. The result is cached.
  #
  def to_do_list
    if @list.nil?
      @list = ToDoList.new
      # Pending Invitees (if the user is allowed to act on them)
      if policy(Invitee).approve?
        count = Invitee.where(approval_state: ApprovalState::PENDING).count
        if count > 0
          @list.items << {
              message: "Act on #{pluralize(count, "invitee")}",
              importance: "danger",
              url: invitees_path
          }
          @list.total_items += count
        end
      end

      # Submissions
      count = current_user.submitted_items.where(submitting: true).count
      if count > 0
        @list.items << {
            message: "Resume #{pluralize(count, "submission")}",
            importance: "info",
            url: deposit_path
        }
        @list.total_items += count
      end
    end
    @list
  end

end