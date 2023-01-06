/**
 * Handles tasks view (/tasks).
 *
 * @constructor
 */
const TasksView = function() {
    const ROOT_URL = $('input[name="root_url"]').val();

    const TaskListRefresher = function() {
        const FREQUENCY = 5000;

        var refreshTimer;

        const refresh = function() {
            console.debug('Refreshing task list...');
            let currentPage = $('.pagination li.active > a:first')
                .text().replace(/[/\D]/g, '');
            if (!currentPage) {
                currentPage = 1;
            }
            const start = (currentPage - 1) * $('[name=limit]').val();
            let path    = "/tasks";
            if (window.location.href.match(/all-tasks/)) {
                path = "/all-tasks";
            }
            const url = ROOT_URL + path + "?start=" + start;

            $.ajax({
                url: url,
                data: $('form.filter').serialize(),
                success: function (data) {
                    // this will be handled by index.js.erb
                }
            });
        };

        this.start = function() {
            refreshTimer = setInterval(refresh, FREQUENCY);
            refresh();
        };

        this.stop = function() {
            clearInterval(refreshTimer);
        }

    };

    this.init = function() {
        new TaskListRefresher().start();

        $('#show-task-modal').on('show.bs.modal', function(event) {
            const modal   = $(this);
            const button  = $(event.relatedTarget);
            const task_id = button.data('task-id');
            const url     = ROOT_URL + "/tasks/" + task_id;
            $.ajax({
                url: url,
                success: function (data) {
                    modal.find('.modal-body').html(data);
                    
                },
                error: function(a, b, c) {
                    console.error(a);
                    console.error(b);
                    console.error(c);
                }
            });
        });
    };

};

$(document).ready(function() {
    if ($('body#tasks').length) {
        new TasksView().init();
    }
});
