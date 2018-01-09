module VCAP::CloudController
  class AppUsageEventAccess < BaseAccess
    def index?(object_class, params=nil)
      context.can_see_secrets_globally?
    end

    def reset?(_)
      admin_user?
    end

    def reset_with_token?(_)
      admin_user?
    end
  end
end
