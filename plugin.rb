# frozen_string_literal: true

# name: discourse-plugin-last-day-used-key
# about: changes last used strategy to use current day instead of current time
# version: 0.0.1
# authors: Marfeel
# url: https://github.com/Marfeel/discourse-plugin-last-day-used-key
# required_version: 2.7.0

enabled_site_setting :discourse_plugin_markdown_html_whitelist_enabled

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
    def update_last_used!(now = nil)
      return if last_used_at && (last_used_at == Time.zone.now.beginning_of_day)

      super(Time.zone.now.beginning_of_day)
    end
  end

  module PostTimingExtensions
    def self.prepended(base)
      base.singleton_class.prepend(ClassMethods)
    end

    module ClassMethods
      def record_new_timing(args)
        logger = Logger.new(STDOUT)

        logger.info("timiiiiiiing overriden")

        row_count =
          DB.exec(
            "INSERT INTO post_timings (topic_id, user_id, post_number, msecs)
                  SELECT :topic_id, :user_id, :post_number, :msecs
                  ON CONFLICT DO NOTHING",
            args,
          )

        return if row_count == 0
        Post.where(
          ["topic_id = :topic_id and post_number = :post_number", args],
        ).update_all "reads = reads + 1"
      end
    end
  end
end

after_initialize do
  ::UserApiKey.prepend(::LastDayUsedKey::UserApiKeyExtensions)
  ::ApiKey.prepend(::LastDayUsedKey::ApiKeyExtensions)
  ::PostTiming.prepend(::LastDayUsedKey::PostTimingExtensions)
end