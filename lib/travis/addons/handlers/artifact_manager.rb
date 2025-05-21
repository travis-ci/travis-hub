require 'travis/addons/handlers/base'
require 'travis/addons/config'

module Travis
  module Addons
    module Handlers
      class ArtifactManager < Base
        EVENTS = ['job:finished', 'job:canceled'].freeze
        KEY = :artifact_manager

        MSGS = {
          failed: 'Failed to push update to artifact-manager: %s'
        }

        def handle?
          res = artifact_manager_url && artifact_manager_auth_key
          puts "HANDLE: #{res.inspect}"
          res
        end

        def handle
          publish unless Travis::Hub.context.config.enterprise?
        end

        private

        def artifact_manager_url
          @artifact_manager_url ||= Travis::Hub.context.config.artifact_manager.url if Travis::Hub.context.config.artifact_manager
        end

        def artifact_manager_auth_key
          @artifact_manager_auth_key ||= Travis::Hub.context.config.artifact_manager.auth_key if Travis::Hub.context.config.artifact_manager
        end

        def publish
          puts "PUBLISH1: ic: #{image_creation?} f: #{failed?}"
          send_data if image_creation? && failed?
        rescue StandardError => e
          logger.error MSGS[:failed] % e.message
        end

        def send_data
          owner_type = object.repository.owner_type.downcase
          owner_id = object.repository.owner_id

          puts "PATCH!"
          puts "IMGNAME: #{image_name}"
          result = connection.patch("#{owner_type}/#{owner_id}/#{image_name}", { state: 'error' })

          logger.error "Artifact manager error: #{result.status} #{result.body}" unless result.success?
        end

        def image_name
          config.dig('vm', 'create', 'name')
        end

        def image_creation?
          !image_name.nil?
        end

        def failed?
          puts "STATE: #{object.state}"
          object.state == 'failed' || object.state == 'errored'
        end

        def config
          @config ||= begin
            cfg = object.config_id ? ::JobConfig.find(object.config_id).config : {}
            cfg.is_a?(String) && cfg.length > 0 ? JSON.parse(cfg) : cfg
          end
        end

        def connection
          @connection ||= Faraday.new(url: artifact_manager_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
            conn.request :authorization, :basic, '_', artifact_manager_auth_key
            conn.headers['Content-Type'] = 'application/json'
            conn.request :json
            conn.response :json
            conn.adapter :net_http
          end
        end

        def logger
          Addons.logger
        end

        def finished?
          event != 'job:started'
        end

        # EventHandler
        class EventHandler < Addons::Instrument
          def notify_completed
            publish
          end
        end
        EventHandler.attach_to(self)
      end
    end
  end
end
