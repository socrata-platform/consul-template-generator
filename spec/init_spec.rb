require 'spec_helper'
require 'webmock'

require 'consul/template/generator'

include Consul::Template::Generator

describe 'Consul::Template::Generator::CTRunner' '#initialize' do
  before(:each) do
    Consul::Template::Generator.configure do |config|
      config.templates = {'test-session-template.ctmpl' => 'test-session-template' }
      config.node = 'test-node'
      config.log_level = :off
      config.consul_template_binary = 'consul-template'
    end
  end

  context 'initialization of Consul::Template::Generator::CTRunner' do
    it "creates session if token isn't passed" do
      runner = Consul::Template::Generator::CTRunner.new
      expect(runner.session).to eql('test-session-id')
      runner.destroy_session
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/create').with(:body => '{"Node":"test-node","Name":"consul-template-generator","Behavior":"release"}')
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/destroy/test-session-id')
      expect(runner.session).to be_nil
    end

    it "destroys previous session on create" do
      runner = Consul::Template::Generator::CTRunner.new 'destroyed-session'
      expect(runner.session).to eql('destroyed-session')
      runner.create_session
      runner.destroy_session
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/create').with(:body => '{"Node":"test-node","Name":"consul-template-generator","Behavior":"release"}')
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/destroy/destroyed-session')
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/destroy/test-session-id')
      expect(runner.session).to be_nil
    end

    it "handles filed session destroys" do
      runner = Consul::Template::Generator::CTRunner.new 'failed-destroyed-session'
      expect(runner.session).to eql('failed-destroyed-session')
      runner.create_session
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/create').with(:body => '{"Node":"test-node","Name":"consul-template-generator","Behavior":"release"}')
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/session/destroy/failed-destroyed-session')
      expect(runner.session).to eql('test-session-id')
    end
  end
end
