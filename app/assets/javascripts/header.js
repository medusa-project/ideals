$(document).ready(function() {
    new IDEALS.UIUtils.ContactForm();
    new IDEALS.UIUtils.NonNetIDLoginForm();
    // Enable Bootstrap popovers. This will have to be called again manually in
    // an XHR success callback if there are any popovers loaded that way.
    IDEALS.UIUtils.enablePopovers();

    // Reimplement the form element data-confirm functionality that used to be
    // in rails-ujs, which is no longer available in Rails 7.
    $("a[data-confirm]").on("click", function(e) {
        e.preventDefault();
        const elem   = $(this);
        const result = confirm(elem.data("confirm"));
        if (result) {
            const form = $("<form method='post'></form>");
            form.attr("action", elem.attr("href"));
            var input = $("<input type='hidden'>");
            input.attr("name", "_method");
            input.attr("value", elem.data("method"));
            form.append(input);
            var input = $("<input type='hidden'>");
            input.attr("name", "authenticity_token");
            input.attr("value", $("meta[name=csrf-token]").attr("content"));
            form.append(input);
            $.each(this.attributes, function() {
                if (this.name.startsWith("data-")) {
                    const input = $("<input type='hidden'>");
                    input.attr("name", this.name.substr(5));
                    input.attr("value", this.value);
                    form.append(input);
                }
            });
            $("body").append(form);
            form.trigger("submit");
        }
        return false;
    });

    // When a modal is closed, clear its form.
    $(".modal").on("hidden.bs.modal", function() {
        $(this).find("input, select, textarea").not("input[type=submit]").val("");
    });

    // Copy the URL "q" argument into the filter field, as the browser won't do
    // this automatically.
    const queryArgs = new URLSearchParams(location.search);
    if (queryArgs.has("q")) {
        $("input[name=q]").val(queryArgs.get("q"));
    }

    // Submit forms when a "sort" select menu changes.
    const sortMenu              = $("[name=sort]");
    const directionButtons      = $("[name=direction]");
    const directionButtionGroup = directionButtons.parents(".btn-group");
    sortMenu.on("change", function() {
        $(this).parents("form:first").submit();
    });
    // Submit forms when a "direction" radio changes.
    directionButtons.on("change", function() {
        $(this).parents("form:first").submit();
    });
    // Hide the direction radios when the sort is by relevance.
    if ($("[name=sort]").val() === "") {
        directionButtionGroup.hide();
    } else {
        directionButtionGroup.show();
    }

    // Don't allow disabled elements to be clicked.
    $("[disabled='disabled']").on("click", function() {
        return false;
    });

    // Initialize Bootstrap toasts
    const toasts = document.querySelectorAll('.toast')
    const toastList = [...toasts]
        .map(toast => new bootstrap.Toast(toast, {}))
        .forEach(toast => toast.show());
});