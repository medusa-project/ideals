Rails.application.config.session_store :active_record_store,
                                       key: "_ideals_session",
                                       expire_after: 1.day