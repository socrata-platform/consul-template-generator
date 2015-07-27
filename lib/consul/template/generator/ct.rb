require 'open4'
require 'digest'

module Consul
  module Template
    module Generator
      class CTRunner
        def render_template(template)
          body = nil
          cmd = %{#{@config.consul_template_binary} -dry -once -template #{template}}
          procs = ::Open4.popen4(*cmd) do |pid, stdin, stdout, stderr|
            body = stdout.read.strip
            # consul-template -dry inserts '> \n' at the top of stdout, remove it
            body.sub!(/^>\s+\n/, '')
          end
          status = procs.to_i
          hash = ::Digest::MD5.hexdigest(body)
          return status, body, hash
        end
      end
    end
  end
end
