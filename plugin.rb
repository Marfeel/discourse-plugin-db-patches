# frozen_string_literal: true

# name: discourse-plugin-last-day-used-key
# about: changes last used strategy to use current day instead of current time
# version: 0.0.1
# authors: Marfeel
# url: https://github.com/Marfeel/discourse-plugin-last-day-used-key
# required_version: 2.7.0

enabled_site_setting :plugin_name_enabled

module ::LastDayUsedKey
  PLUGIN_NAME = "discourse-plugin-last-day-used-key"

  module UserApiKeyExtensions
    def update_last_used(client_id)
      update_args = {}

      if self.last_used_at != Time.zone.now.beginning_of_day
        update_args[:last_used_at] = Time.zone.now.beginning_of_day
      end

      if client_id.present? && client_id != self.client_id
        UserApiKey
          .where(client_id: client_id, user_id: self.user_id)
          .where("id <> ?", self.id)
          .destroy_all

        update_args[:client_id] = client_id
      end

      self.update_columns(**update_args) if update_args.present?
    end
  end

  module ApiKeyExtensions
    def update_last_used!(now)
      super(Time.zone.now.beginning_of_day)
    end
  end
end

after_initialize do
  ::UserApiKey.prepend(::LastDayUsedKey::UserApiKeyExtensions)
  ::ApiKey.prepend(::LastDayUsedKey::ApiKeyExtensions)
end
