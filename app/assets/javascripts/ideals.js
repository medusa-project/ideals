/**
 * Namespace for componenents that are shared across views.
 */
const IDEALS = {

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

    $("a[disabled='disabled']").on("click", function() {
        return false;
    });
};
$(document).ready(ideals_ready);
$(document).on('page:load', ideals_ready);