module Consul
  module Template
    module Generator
      class CTRunner
        attr_accessor :session

        def initialize(consul_session_id = nil)
          if consul_session_id.nil?
            consul_session_id = Consul::Template::Generator.create_session 'consul-template-generator'
          end
          @session = consul_session_id
          @config = Consul::Template::Generator.config
        end
      end
    end
  end
end
