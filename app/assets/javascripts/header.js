$(document).ready(function() {
    new IDEALS.UIUtils.ContactForm();
    new IDEALS.UIUtils.NonNetIDLoginForm();
    // Enable Bootstrap popovers. This will have to be called again manually in
    // an XHR success callback if there are any popovers loaded that way.
    IDEALS.UIUtils.enablePopovers();

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