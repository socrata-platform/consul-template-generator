module Consul
  module Template
    module Generator
      class CTRunner
        attr_accessor :session

        def initialize(consul_session_id = nil, do_create_session = true)
          if (consul_session_id.nil? && do_create_session)
            create_session
          else
            @session = consul_session_id
          end
          @config = Consul::Template::Generator.config
        end

        def create_session
          unless @session.nil?
            destroy_session
          end
          @session = Consul::Template::Generator.create_session 'consul-template-generator'
        end

        def destroy_session
          begin
            Consul::Template::Generator.destroy_session @session
          rescue
            Consul::Template::Generator.config.logger.info "Failed to destroy session: #{@session}"
          end
          @session = nil
        end
      end
    end
  end
end
