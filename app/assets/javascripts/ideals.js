/**
 * Namespace for componenents that are shared across views.
 */
const IDEALS = {

    /**
     * Application-wide fade time, for consistency.
     */
    FADE_TIME: 200,

    /**
     * Counterpart to {@link MetadataEditor} for use in the deposit form.
     *
     * @constructor
     */
    DepositMetadataEditor: function() {
        refreshRemoveButtons();
        wireRemoveButtons();

        $("button.add").on("click", function(e) {
            // Show the "remove" button of all adjacent input groups
            const inputGroups = $(this).parent().find(".input-group");
            inputGroups.find(".input-group-append").show();
            // Clone the last input group
            const prevInputGroup = inputGroups.filter(":last");
            const clone = prevInputGroup.clone();
            clone.find("input[type=text], textarea").val("");
            // Insert the clone after the last input group
            prevInputGroup.after(clone);
            wireRemoveButtons();
            e.preventDefault();
        });

        /**
         * Shows all adjacent input groups' "remove" buttons if there are two
         * or more of them, and hides them (it) if not.
         */
        function refreshRemoveButtons() {
            $("button.remove").each(function() {
                const button = $(this);
                const parentInputGroup = button.parents(".input-group");
                if (parentInputGroup.siblings(".input-group").length > 0) {
                    button.parent().show();
                } else {
                    button.parent().hide();
                }
            });
        }

        function wireRemoveButtons() {
            $("button.remove").off("click").on("click", function(e) {
                const parentInputGroup = $(this).parents(".input-group");
                if (parentInputGroup.siblings(".input-group").length > 0) {
                    parentInputGroup.remove();
                }
                refreshRemoveButtons();
                e.preventDefault();
            });
        }
    },

    FacetSet: function() {
        /**
         * Enables the facets returned by one of the facets_as_x() helpers.
         */
        this.init = function() {
            $("[name='fq[]']").off().on("change", function () {
                if ($(this).prop("checked")) {
                    window.location = $(this).data("checked-href");
                } else {
                    window.location = $(this).data("unchecked-href");
                }
            });
        }
    },

    MetadataEditor: function() {
        $("button.add").on("click", function(e) {
            const last_tr = $(this).parent(".form-group").find("table.metadata > tbody > tr:last-child");
            const clone = last_tr.clone();
            clone.find("input").val("");
            last_tr.after(clone);
            updateEventListeners();
            e.preventDefault();
        });
        updateEventListeners();

        function updateEventListeners() {
            $("button.remove").off("click").on("click", function () {
                if ($(this).parents("table").find("tr").length > 1) {
                    $(this).parents("tr").remove();
                }
            });
        }
    },

    MultiUserList: function() {
        $("button.add").on("click", function(e) {
            const clone = $(this).prev().clone();
            clone.find("input").val("");
            $(this).before(clone);
            updateEventListeners();
            new IDEALS.UserAutocompleter(clone.find("input"));
            e.preventDefault();
        });
        updateEventListeners();

        function updateEventListeners() {
            $("button.remove").off("click").on("click", function () {
                if ($(this).parents(".form-group").find(".user").length > 1) {
                    $(this).parents(".user").remove();
                }
            });
        }
    },

    NonNetIDLoginForm: function() {
        const root_url = $('input[name=root_url]').val();
        const modal    = $('#non-netid-login-modal');
        const flash    = modal.find('.alert');
        modal.find('button[type=submit]').on('click', function(event) {
            $.ajax({
                url: root_url + '/auth/identity/callback',
                method: 'post',
                data: $(this).parents('form').serialize(),
                success: function(data, status, xhr) {
                    modal.on('hidden.bs.modal', function () {
                        location.reload();
                    });
                    flash.removeClass('alert-danger')
                        .addClass('alert-success')
                        .text('Login succeeded. One moment...')
                        .show();
                    setTimeout(function() {
                        modal.modal('hide');
                    }, 2000);
                },
                error: function(e) {
                    flash.removeClass('alert-success')
                        .addClass('alert-danger')
                        .text('Login failed.')
                        .show();
                }
            });
            event.preventDefault();
        });
    },

    /**
     * @param textField jQuery text field element.
     * @constructor
     */
    UserAutocompleter: function(textField) {
        const MAX_RESULTS = 8;
        const ROOT_URL = $('input[name="root_url"]').val();
        textField.on("keyup", function() {
            const textField = $(this);
            const menu      = textField.parent().find(".dropdown-menu");
            const query     = textField.val();
            if (query.length < 1) {
                menu.hide();
                return;
            }
            menu.css("top", $(this).position().top + $(this).height() + 14 + "px");
            menu.css("left", "14px");

            $.ajax({
                url: ROOT_URL + "/users.json?window=" + MAX_RESULTS + "&q=" + query,
                method: "get",
                success: function(data, status, xhr) {
                    if (data['numResults'] > 0) {
                        menu.empty();
                        data['results'].forEach(function(result) {
                            const menuItem = $("<div class=\"dropdown-item\"></div>");
                            // It's important that all menu items be unique
                            // across all users. For users that have a name, we
                            // append their email. For unnamed users, we include
                            // only their email.
                            if (result['name'].length > 0) {
                                menuItem.html(result['name'] +
                                    " <small>(" + result['email'] + ")</small>");
                            } else {
                                menuItem.html(result['email']);
                            }
                            menu.append(menuItem);
                            menuItem.on("click", function() {
                                textField.val($(this).text());
                                menu.hide();
                            });
                        });
                        menu.show();
                    } else {
                        menu.hide();
                    }
                },
                error: function(e) {
                    console.error(e);
                }
            });
        });
    }
};

const ideals_ready = function () {

    // dynamically hide/show long text

    //$("ul.context-info").hide();

    var showChar = 140;
    var ellipsestext = "...";
    var moretext = "more";
    var lesstext = "less";
    $('.more').each(function () {
        var content = $(this).html();

        if (content.length > showChar) {

            var c = content.substr(0, showChar);
            var h = content.substr(showChar, content.length - showChar);

            var html = c + '<span class="moreellipses">' + ellipsestext + '&nbsp;</span><span class="morecontent"><span>' + h + '</span>&nbsp;&nbsp;<a href="" class="morelink">' + moretext + '</a></span>';

            $(this).html(html);
        }

    });

    // Copy the URL "q" argument into the filter field, as the browser won't do
    // this automatically.
    const queryArgs = new URLSearchParams(location.search);
    if (queryArgs.has("q")) {
        $("input[name=q]").val(queryArgs.get("q"));
    }

    $(".morelink").click(function () {
        if ($(this).hasClass("less")) {
            $(this).removeClass("less");
            $(this).html(moretext);
        } else {
            $(this).addClass("less");
            $(this).html(lesstext);
        }
        $(this).parent().prev().toggle();
        $(this).prev().toggle();
        return false;
    });

    // Submit forms when a "sort" select menu changes.
    $("[name=sort]").on("change", function() {
        $(this).parents("form:first").submit();
    });

    // Save the last-selected tab in a cookie.
    $('a[data-toggle="tab"]').on('click', function(e) {
        Cookies.set('last_tab', $(e.target).attr('href'));
    });

    // Activate the cookie-stored tab, if it exists.
    const lastTab = Cookies.get('last_tab');
    if (lastTab) {
        $('a[href="' + lastTab + '"]').click();
    }

    // Don't allow disabled anchors to be clicked.
    $("a[disabled='disabled']").on("click", function() {
        return false;
    });
};
$(document).ready(ideals_ready);