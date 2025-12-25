require 'travis/addons/handlers/base'
require 'travis/addons/handlers/task'

module Travis
  module Addons
    module Handlers
      class Webhook < Notifiers
        EVENTS = /build:(started|finished|canceled|errored)/
        KEY = :webhooks

        class Notifier < Notifier
          def handle?
            targets.present? && config.send_on?(:webhooks, action)
          end

          def handle
            run_task(:webhook, payload, targets:, token: request.token, msteams: msteams_flags)
          end

          def targets
            @targets ||= begin
              urls = []
              raw_config = config.config

              # Handle different config formats
              if raw_config.is_a?(Hash)
                urls_config = raw_config[:urls]

                if urls_config.is_a?(Array)
                  urls_config.each do |item|
                    urls << if item.is_a?(Hash)
                              item[:url] || item['url']
                            else
                              item
                            end
                  end
                elsif urls_config.is_a?(String)
                  urls = urls_config.split(',').map(&:strip)
                elsif urls_config
                  urls << urls_config.to_s
                end
              elsif raw_config.is_a?(Array)
                # Direct array of URLs
                raw_config.each do |item|
                  urls << if item.is_a?(Hash)
                            item[:url] || item['url']
                          else
                            item
                          end
                end
              elsif raw_config.is_a?(String)
                # Direct string (comma-separated URLs)
                urls = raw_config.split(',').map(&:strip)
              end

              urls.push(*global_urls).compact
            end
          end

          def global_urls
            @global_urls ||= ENV['TRAVIS_HUB_WEBHOOK_GLOBAL_URLS']&.split(';') || []
          end

          # Returns hash mapping URLs to msteams flags
          # e.g., { 'https://url1' => true, 'https://url2' => false }
          def msteams_flags
            @msteams_flags ||= begin
              flags = {}
              raw_config = config.config

              # Handle different config formats
              if raw_config.is_a?(Hash)
                urls_config = raw_config[:urls]

                if urls_config.is_a?(Array)
                  urls_config.each do |item|
                    if item.is_a?(Hash)
                      url = item[:url] || item['url']
                      msteams = item[:msteams] || item['msteams'] || false
                      flags[url] = msteams
                    else
                      # Plain URL strings get false flag
                      flags[item] = false
                    end
                  end
                end
              elsif raw_config.is_a?(Array)
                # Direct array format
                raw_config.each do |item|
                  if item.is_a?(Hash)
                    url = item[:url] || item['url']
                    msteams = item[:msteams] || item['msteams'] || false
                    flags[url] = msteams
                  else
                    flags[item] = false
                  end
                end
              end

              # Global URLs never have msteams flag
              global_urls.each { |url| flags[url] = false }

              flags
            end
          end

          class Instrument < Addons::Instrument
            def notify_completed
              publish(targets: handler.targets)
            end
          end
          Instrument.attach_to(self)
        end
      end
    end
  end
end
