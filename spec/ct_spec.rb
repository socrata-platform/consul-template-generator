require 'spec_helper'
require 'stringio'

require 'open4'
require 'consul/template/generator'

include Consul::Template::Generator

def setup_open4(stdout, exit_code, pid)
  @pid = pid
  @status = exit_code
  @stdin = StringIO.new
  @stdout = StringIO.new
  @stderr = StringIO.new

  @stdout_string = "> \n#{stdout}"

  @stdout << stdout
  @stdout.rewind

  allow(Open4).to receive(:popen4).and_yield(@pid, @stdin, @stdout, @stderr).and_return(@status)
end

describe 'Consul::Template::Generator::CTRunner' '#render_template' do
  before do
    Consul::Template::Generator.configure do |config|
      config.templates = {'/etc/test-template.ctmpl' => '/test-template'}
      config.consul_template_binary = 'consul-template'
    end
  end

  context 'render template' do
    it 'runs successfully' do
      exp_out = 'this is a test'
      exp_hash = '54b0c58c7ce9f2a8b551351102ee0938'
      setup_open4(exp_out, 0, 101)
      runner = CTRunner.new('test-session')
      exit_code, body, hash = runner.render_template Consul::Template::Generator.config.templates['/etc/test-template.ctmpl']
      expect(body).to eql(exp_out)
      expect(hash).to eql(exp_hash)
      expect(exit_code).to eql(@status)
    end
  end
end
