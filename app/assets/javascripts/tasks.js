/**
 * Handles tasks view (/tasks).
 */
const TasksView = {

    initialize: function() {
        const ROOT_URL  = $("input[name='root_url']").val();
        const filterDiv = $("#task-filter");
        const form      = filterDiv.find("form");

        const attachResultsEventListeners = function () {
            $(".page-link").on("click", function (e) {
                e.preventDefault();
                refreshResults($(this).attr("href"));
            });
        };
        attachResultsEventListeners();

        const refreshResults = function (url) {
            if (!url) {
                url = form.attr("action");
            }
            $.ajax({
                method: "GET",
                url: url,
                data: form.serialize(),
                dataType: "script",
                success: function (data) {
                    $("#tasks-list").html(data);
                    attachResultsEventListeners();
                },
                error: function (data, status, xhr) {
                }
            });
        };

        setInterval(function () {
            refreshResults($(".page-item.active a").attr("href"));
        }, IDEALS.UIUtils.REFRESH_FREQUENCY);

        let timeout = null;
        filterDiv.find("input").on("keyup", function () {
            clearTimeout(timeout);
            timeout = setTimeout(function () {
                refreshResults();
            }, IDEALS.UIUtils.KEY_DELAY);
        });
        filterDiv.find("[name=status]").on("change", function () {
            refreshResults();
        });

        $('#show-task-modal').on('show.bs.modal', function (event) {
            const modal   = $(this);
            const button  = $(event.relatedTarget);
            const task_id = button.data("task-id");
            const url     = ROOT_URL + "/tasks/" + task_id;
            $.ajax({
                url: url,
                success: function (data) {
                    modal.find(".modal-body").html(data);
                },
                error: function (a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });
    }

};

$(document).ready(function() {
    if ($("body#tasks").length) {
        TasksView.initialize();
    }
});
