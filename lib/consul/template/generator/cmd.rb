require 'consul/template/generator'

module Consul
  module Template
    module Generator
      module CMD
        include Consul::Template::Generator
        class << self

          def configure(consul_host, templates, session_key, log_level, proxy = nil)
            Consul::Template::Generator.configure do |config|
              config.log_level = log_level
              config.templates = templates
              config.session_key = session_key
              config.consul_host = consul_host
            end
            @config = Consul::Template::Generator.config
          end

          def signals
            Signal.trap("INT") do
              @config.logger.error "Received INT signal..."
              @interrupted = true
            end
            Signal.trap("TERM") do
              @config.logger.error "Received TERM signal..."
              @terminated = true
              @interrupted = true
            end
          end

          def run(cycle_sleep = nil, lock_sleep = nil)
            signals
            @terminated = false
            cycle_sleep ||= 0.5
            lock_sleep ||= 1.0
            uploaded_hashes = {}
            runner = CTRunner.new nil, false
            begin
              runner.create_session
              @interrupted = false
              runner.acquire_session_lock do
                @config.logger.info "Session lock acquired..."
                begin
                  @config.templates.each do |template,template_key|
                    uploaded_hashes[template] = runner.run(template, template_key, uploaded_hashes[template]) || uploaded_hashes[template]
                    sleep cycle_sleep
                  end
                rescue ConsulSessionExpired
                  @config.logger.error "The current consul session has expired."
                  break
                rescue Exception => e
                  @config.logger.error "An error occurred while updating template: #{e.message}"
                  @config.logger.debug "Sleeping before attempting to update again..."
                  sleep lock_sleep
                  break
                end until @interrupted
              end
            rescue Exception => e
              @config.logger.info "Unable to obtain session lock: #{e.message}"
              @config.logger.debug "Sleeping before attempting lock session again..."
              sleep lock_sleep
            ensure
              runner.destroy_session
            end until @terminated
            0
          end

          def run_once
            begin
              @config.templates.each do |template,template_key|
                runner = CTRunner.new
                result = runner.run template, template_key
              end
            rescue Exception => e
              @config.logger.error "An unexpected error occurred, unable to process template: #{e.message}"
              1
            else
              0
            end
          end
        end
      end
    end
  end
end
