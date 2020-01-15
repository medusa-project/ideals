const WelcomeView = function() {
    new IDEALS.NonNetIDLoginForm();
};

var ready = function() {
    if ($('body#welcome').length > 0) {
        WelcomeView();
    }
};

$(document).ready(ready);
$(document).on('page:load', ready);
