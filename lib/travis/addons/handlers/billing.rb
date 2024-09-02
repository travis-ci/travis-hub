require 'travis/addons/handlers/base'
require 'travis/addons/config'

module Travis
  module Addons
    module Handlers
      class Billing < Base
        EVENTS = ['job:started', 'job:finished', 'job:canceled'].freeze
        KEY = :billing

        MSGS = {
          failed: 'Failed to push stats to billing-v2: %s'
        }

        def handle?
          billing_url && billing_auth_key
        end

        def handle
          publish unless Travis::Hub.context.config.enterprise?
        end

        private

        def billing_url
          @billing_url ||= Travis::Hub.context.config.billing.url if Travis::Hub.context.config.billing
        end

        def billing_auth_key
          @billing_auth_key ||= Travis::Hub.context.config.billing.auth_key if Travis::Hub.context.config.billing
        end

        def publish
          send_usage(data)
        rescue StandardError => e
          logger.error MSGS[:failed] % e.message
        end

        def send_usage(data)
          logger.info "Hub usage #{data}"
          Travis::Sidekiq.billing(data)
        end

        def data
          @data ||= serialize_data
        end

        def serialize_data
          {
            job: job_data,
            repository: repository_data,
            owner: owner_data,
            build: build_data
          }
        end

        def job_data
          {
            id: object.id,
            os: config['os'] || 'linux',
            instance_size: meta(:vm_size) || vm_size,
            arch: config['arch'] || 'amd64',
            started_at: object.started_at,
            finished_at: object.finished_at,
            virt_type: config['virt'],
            queue: object.queue,
            vm_size: vm_size,
            finished: finished?
          }
        end

        def repository_data
          {
            id: repository.id,
            slug: repository.slug,
            private: repository.private
          }
        end

        def owner_data
          {
            type: object.owner_type,
            id: object.owner_id,
            login: object.owner ? object.owner.login : nil
          }
        end

        def build_data
          {
            id: object.build.id,
            type: object.build.event_type,
            number: object.build.number,
            branch: object.build.branch,
            sender: build_data_sender
          }
        end

        def build_data_sender
          {
            id: object.build.sender_id,
            type: object.build.sender_type
          }
        end

        def meta(value)
          params[:worker_meta][0][value] if params.has_key?(:worker_meta) && params[:worker_meta].is_a?(Array) && params[:worker_meta].first.respond_to?(:keys)
        end

        def vm_size
          config.dig('vm', 'size')
        end

        def config
          @config ||= begin
            cfg = object.config_id ? ::JobConfig.find(object.config_id).config : {}
            cfg.is_a?(String) && cfg.length > 0 ? JSON.parse(cfg) : cfg
          end
        end

        def connection
          @connection ||= Faraday.new(url: billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
            conn.request :authorization, :basic, '_', billing_auth_key
            conn.headers['Content-Type'] = 'application/json'
            conn.request :json
            conn.response :json
            conn.adapter :net_http
          end
        end

        def handle_usage_executions_response(response)
          case response.status
          when 404
            raise StandardError, "Not found #{response.body['error'] || response.body}"
          when 400
            raise StandardError, "Client error #{response.body['error'] || response.body}"
          when 422
            raise StandardError, "Unprocessable entity #{response.body['error'] || response.body}"
          else
            raise StandardError, "Server error #{response.body['error'] || response.body}"
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

        class BillingError < StandardError; end
      end
    end
  end
end
