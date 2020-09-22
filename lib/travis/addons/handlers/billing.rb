require 'travis/addons/handlers/base'
require 'travis/addons/config'

module Travis
  module Addons
    module Handlers
      class Billing < Base
        EVENTS = ['build:finished', 'job:finished', 'job:canceled'].freeze
        KEY = :billing

        MSGS = {
          failed: 'Failed to push stats to billing-v2: %s'
        }

        def initialize(event, params = {})
          super
          @event_type = event.split(':').first
        end

        def handle?
          billing_url && billing_auth_key
        end

        def handle
          if @event_type == 'job'
            publish_job
          else
            publish_build
          end
        end

        private

        def billing_url
          @billing_url ||= Travis::Hub.context.config.billing.url if Travis::Hub.context.config.billing
        end

        def billing_auth_key
          @billing_auth_key ||= Travis::Hub.context.config.billing.auth_key if Travis::Hub.context.config.billing
        end

        def publish_build
          send_user_usage(user_usage_data)
        rescue => e
          logger.error MSGS[:failed] % e.message
        end

        def publish_job
          send_usage_executions(usage_executions_data)
        rescue => e
          logger.error MSGS[:failed] % e.message
        end

        def send_user_usage(data)
          response = connection.post('/v2/subscriptions/user_usage', data)
          handle_usage_executions_response(response) unless response.success?
        end

        def send_usage_executions(data)
          response = connection.post('/usage/executions', data)
          handle_usage_executions_response(response) unless response.success?
        end

        def usage_executions_data
          @usage_executions_data ||= serialize_data
        end

        def user_usage_data
          @user_usage_data ||= serialize_user_usage
        end

        def serialize_data
          {
            job: job_data,
            repository: repository_data,
            owner: owner_data,
            build: build_data(object.build)
          }
        end

        def serialize_user_usage
          {
            repository: repository_data,
            owner: owner_data,
            build: build_data(object)
          }
        end

        def job_data
          {
            id: object.id,
            os: config['os'] || 'linux',
            instance_size: nil,
            arch: config['arch'] || 'amd64',
            started_at: object.started_at,
            finished_at: object.finished_at,
            virt_type: config['virt'] || config['vm'],
            queue: object.queue
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

        def build_data(obj)
          {
            id: obj.id,
            type: obj.event_type,
            number: obj.number,
            branch: obj.branch,
            sender: build_data_sender(obj)
          }
        end

        def build_data_sender(obj)
          {
            id: obj.sender_id,
            type: obj.sender_type
          }
        end

        def config
          @config ||= object.config_id ? JobConfig.find(object.config_id).config : {}
        end

        def connection
          @connection ||= Faraday.new(url: billing_url, ssl: { ca_path: '/usr/lib/ssl/certs' }) do |conn|
            conn.basic_auth '_', billing_auth_key
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
