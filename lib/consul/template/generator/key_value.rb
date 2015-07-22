require 'diplomat'

module Consul
  module Template
    module Generator
      class CTRunner

        def acquire_lock(lock_key = nil)
          lock_key ||= @config.lock_key
          @config.logger.debug "Attempting to acquire lock on key: #{lock_key}"
          Consul::Template::Generator.renew_session @session
          unless Diplomat::Lock.acquire(lock_key, @session)
            raise KeyNotLockedError, "Unable to acquire lock on key: #{lock_key}"
          end
          @config.logger.debug "Lock acquired on key: #{lock_key}"

          begin
            yield
          ensure
            Diplomat::Lock.release(lock_key, @session)
          end
        end

        def acquire_session_lock
          acquire_lock(@config.session_lock_key) do
            yield
          end
        end

        def upload_template(raw_template)
          @config.logger.info "Uploading key: #{@config.template_key}"
          begin
            Diplomat::Kv.put(@config.template_key, raw_template)
          rescue Exception => e
            raise TemplateUploadError, "Encountered an unexpected error while uploading template: #{e.message}"
          end
        end
      end
    end
  end
end

