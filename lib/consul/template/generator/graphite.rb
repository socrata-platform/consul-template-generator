require 'socket'

module Consul
  module Template
    module Generator
      class CTRunner
        def post_graphite_event(path)
          @config.logger.debug "Posting event to graphite. Server: #{@config.graphite_host}, Path: #{path}"
          host, port = @config.graphite_host.split(':')
          begin
            s = TCPSocket.open(host, port)
            s.write("#{path} 1 #{Time.new.to_i}\n")
            s.close
          rescue Exception => e
            @config.logger.error "An unknown error occurred while posting data to graphite: #{e.message}"
          end
        end
      end
    end
  end
end
