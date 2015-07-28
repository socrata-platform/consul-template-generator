require_relative 'generator/cmd'
require_relative 'generator/ct'
require_relative 'generator/configuration'
require_relative 'generator/error'
require_relative 'generator/init'
require_relative 'generator/key_value'
require_relative 'generator/run'
require_relative 'generator/version'

require 'diplomat'
require 'faraday'

module Consul
  module Template
    module Generator
      class << self
        attr_accessor :config
        attr_accessor :create_session, :renew_session, :destroy_session
        def configure
          self.config ||= Consul::Template::Generator::Configuration.new
          self.config.node = `hostname`.strip
          self.config.consul_host = '127.0.0.1:8500'

          yield self.config

          if self.config.consul_template_binary.nil?
            ct_binary = `which consul-template`.strip
            if ct_binary.empty?
              raise "consul-template must be in your $PATH or configure the location to the executable"
            end
            self.config.consul_template_binary = ct_binary
          end

          if self.config.templates.empty? || self.config.templates.any? { |k,v| v.nil? }
            raise "template must be defined in configuration"
          end

          Diplomat.configure do |config|
            config.url = "http://#{self.config.consul_host}"
            config.options = self.config.client_options
          end
        end

        def create_session(name)
          Diplomat::Session.create({:Node => self.config.node, :Name => name, :Behavior => 'release'})
        end

        def renew_session(sess_id)
          # There is an outstanding bug in Diplomat::Session.renew with a PR to fix
          # https://github.com/WeAreFarmGeek/diplomat/issues/43
          begin
            Diplomat::Session.renew sess_id
          rescue Faraday::ResourceNotFound
            raise ConsulSessionExpired
          rescue Exception => e
            # Letting this go for the time being, until the above issue is fixed
            self.config.logger.error "Unknown error occurred: #{e.message}"
          end
        end

        def destroy_session(sess_id)
          Diplomat::Session.destroy sess_id
        end
      end
    end
  end
end
