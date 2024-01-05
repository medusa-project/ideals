require "request_context"
Rails.application.config.active_job.custom_serializers << ::RequestContext::RequestContextSerializer
