require 'consul/template/generator'

module Consul
  module Template
    module Generator
      module CMD
        include Consul::Template::Generator
        class << self

          def configure(consul_host, templates, session_key, log_level, graphite_host = nil, graphite_paths = nil, diff_changes = false)
            Consul::Template::Generator.configure do |config|
              config.log_level = log_level
              config.templates = templates
              config.session_key = session_key
              config.consul_host = consul_host
              config.graphite_host = graphite_host
              config.graphite_paths = graphite_paths || {}
              config.diff_changes = diff_changes
            end
            @config = Consul::Template::Generator.config
          end

          def configure_signal_handlers
            Signal.trap("INT") do
              @config.logger.error "Received INT signal..."
              @terminated = true
              @interrupted = true
            end
            Signal.trap("TERM") do
              @config.logger.error "Received TERM signal..."
              @terminated = true
              @interrupted = true
            end
          end

          def run(cycle_sleep = nil, lock_sleep = nil)
            configure_signal_handlers
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
                    new_hash = runner.run(template, template_key, uploaded_hashes[template], @config.diff_changes)
                    unless new_hash.nil?
                      uploaded_hashes[template] =  new_hash
                      if @config.graphite_paths.include? template
                        runner.post_graphite_event @config.graphite_paths[template]
                      end
                    end
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
                result = runner.run(template, template_key, nil, @config.diff_changes)
                unless result.nil?
                  if @config.graphite_paths.include? template
                    runner.post_graphite_event @config.graphite_paths[template]
                  end
                end
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
