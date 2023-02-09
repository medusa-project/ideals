// This is the last file included in application.js.

$(document).ready(function() {
    // Save the last-selected tab in a cookie.
    $('[data-bs-toggle="tab"], [data-bs-toggle="pill"]').on('click', function(e) {
        Cookies.set('selectedTabs', $(e.target).attr('data-bs-target'));
    });

    // Activate the cookie-stored tab, if it exists.
    const lastTab = Cookies.get('selectedTabs');
    if (lastTab) {
        $('[data-bs-target="' + lastTab + '"]').click();
    }
});
