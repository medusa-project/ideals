/**
 * Handles registration view.
 */
const RegistrationView = {

    initialize: function() {
        IDEALS.UIUtils.PasswordRequirements();
    }

};

$(document).ready(function() {
    if ($("body#register").length) {
        RegistrationView.initialize();
    }
});
