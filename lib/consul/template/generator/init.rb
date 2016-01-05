module Consul
  module Template
    module Generator
      class CTRunner
        attr_accessor :session

        def initialize(consul_session_id = nil, do_create_session = true)
          @config = Consul::Template::Generator.config
          if (consul_session_id.nil? && do_create_session)
            create_session
          else
            @session = consul_session_id
          end
        end

        def create_session
          unless @session.nil?
            destroy_session
          end
          @session = Consul::Template::Generator.create_session @config.session_name, @config.session_ttl
        end

        def destroy_session
          return if @session.nil?
          attempts = 0
          begin
            destroyed = Consul::Template::Generator.destroy_session @session
          rescue
            Consul::Template::Generator.config.logger.info "Failed to destroy session: #{@session}, attempt number #{attempts}"
          ensure
            @session = destroyed ? nil : @session
            unless @session.nil?
              attempts += 1
              sleep 0.25
            end
          end until (@session.nil? || attempts > 4)
        end
      end
    end
  end
end
