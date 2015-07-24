require 'spec_helper'
require 'webmock'

require 'consul/template/generator'

include Consul::Template::Generator

describe 'Consul::Template::Generator::CTRunner' '#initialize' do
  before do
    Consul::Template::Generator.configure do |config|
      config.template = 'test-session-template.ctmpl'
      config.template_key = 'test-session-template'
      config.node = 'test-node'
      config.consul_template_binary = 'consul-template'
    end
  end

  context 'initialization of Consul::Template::Generator::CTRunner' do
    it "creates session if token isn't passed" do
      @runner = Consul::Template::Generator::CTRunner.new
      expect(WebMock).to_not have_requested(:put, 'http://127.0.0.1:8500/v1/kv/session/create').with(:body => "{\"Node\": \"test-node\", \"Name\": \"consul-template-generator\"}")
      expect(@runner.session).to eql('test-session-id')
    end
  end
end
