module Travis
  class Hub
    class Handler
      # Handles worker status events which are sent by the worker heartbeat.
      class Worker < Handler
        def handle
          # TODO hot compat, remove the next line once all workers send the new payload
          reports = payload.is_a?(Hash) ? payload['workers'] || payload : payload
          reports = [reports] if reports.is_a?(Hash)
          Travis.run_service(:update_worker, reports: reports)
        end
        instrument :handle
        new_relic :handle
      end
    end
  end
end
