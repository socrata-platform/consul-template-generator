module Consul
  module Template
    module Generator
      module STDLogLvl
        class << self
          def debug() 1 end
          def info() 2 end
          def error() 3 end
          def off() 4 end
        end
      end

      module STDLogger
        class << self
          def do_log?(requested_lvl, curr_lvl)
            curr_lvl = Consul::Template::Generator::STDLogLvl.send(curr_lvl.to_sym)
            requested_lvl = Consul::Template::Generator::STDLogLvl.send(requested_lvl.to_sym)
            requested_lvl >= curr_lvl
          end

          def debug(msg)
            if do_log?(:debug, Consul::Template::Generator.config.log_level)
              STDOUT.puts "[DEBUG] #{msg}"
            end
          end

          def info(msg)
            if do_log?(:info, Consul::Template::Generator.config.log_level)
              STDOUT.puts "[INFO] #{msg}"
            end
          end

          def error(msg)
            if do_log?(:error, Consul::Template::Generator.config.log_level)
              STDERR.puts "[ERROR] #{msg}"
            end
          end
        end
      end

      class Configuration
        attr_accessor :template, :template_key, :consul_template_binary, :logger, :log_level
        attr_accessor :consul_host, :node, :client_options

        def initialize
          @log_level = :debug
          @node = nil
          @consul_host = nil
          @template = nil
          @template_key = nil
          @client_options = {}
          @logger = Consul::Template::Generator::STDLogger
        end

        def lock_key
          "/lock/#{@template_key.sub(/^\//, '')}"
        end

        def session_lock_key
          "/lock/session/#{@template_key.sub(/^\//, '')}"
        end
      end
    end
  end
end
