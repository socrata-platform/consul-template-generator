require 'spec_helper'
require 'stringio'
require 'webmock'

require 'open4'
require 'consul/template/generator'

include Consul::Template::Generator

describe 'Consul::Template::Generator::CTRunner' '#acquire_lock' do
  before do
    Consul::Template::Generator.configure do |config|
      config.template = 'test-template.ctmpl'
      config.template_key = '/test-template'
      config.consul_host = '127.0.0.1:8500'
      config.log_level = :off
    end
  end

  context 'acquires lock' do
    it 'clean lock acquisition' do
      runner = CTRunner.new('test-session')
      runner.acquire_lock do
       expect(true).to be_truthy ## This is simply to assert we are able to execute code in the block
      end
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/test-template').with(:query => {:acquire => 'test-session'})
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/test-template').with(:query => {:release => 'test-session'})
    end

    it 'handles being unable to acquire lock' do
      runner = CTRunner.new('test-session-lock-fail')
      expect { runner.acquire_lock { puts 'hi' } }.to raise_error(KeyNotLockedError)
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/test-template').with(:query => {:acquire => 'test-session-lock-fail'})
      expect(WebMock).to_not have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/test-template').with(:query => {:release => 'test-session-lock-fail'})
    end
  end
end

describe 'Consul::Template::Generator::CTRunner' '#acquire_session_lock' do
  before do
    Consul::Template::Generator.configure do |config|
      config.template = 'test-template.ctmpl'
      config.template_key = '/test-template'
      config.consul_host = '127.0.0.1:8500'
      config.log_level = :off
    end
  end

  context 'acquires session lock' do
    it 'clean lock acquisition' do
      runner = CTRunner.new('test-session')
      runner.acquire_session_lock do
       expect(true).to be_truthy ## This is simply to assert we are able to execute code in the block
      end
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/session/test-template').with(:query => {:acquire => 'test-session'})
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/session/test-template').with(:query => {:release => 'test-session'})
    end

    it 'handles being unable to acquire session lock' do
      runner = CTRunner.new('test-session-lock-fail')
      expect { runner.acquire_session_lock { puts 'hi' } }.to raise_error(KeyNotLockedError)
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/lock/session/test-template').with(:query => {:acquire => 'test-session-lock-fail'})
      expect(WebMock).to_not have_requested(:put, 'http://127.0.0.1:8500/v1/kv/session/lock/test-template').with(:query => {:release => 'test-session-lock-fail'})
    end
  end
end

describe 'Consul::Template::Generator::CTRunner' '#upload_template' do
  context 'uploads template' do
    before do
      Consul::Template::Generator.configure do |config|
        config.template = 'test-template.ctmpl'
        config.template_key = '/test-template'
        config.consul_host = '127.0.0.1:8500'
        config.log_level = :off
      end
    end

    it 'does a clean upload' do
      runner = CTRunner.new('test-session')
      success = runner.upload_template('this is a test')
      expect(success).to be_truthy
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/test-template').with(:body => 'this is a test')
    end
  end

  context 'handles template upload failure' do
    before do
      Consul::Template::Generator.configure do |config|
        config.template = 'test-template.ctmpl'
        config.template_key = '/test-template-failure'
        config.consul_host = '127.0.0.1:8500'
        config.log_level = :off
      end
    end

    it 'does a clean upload' do
      runner = CTRunner.new('test-session')
      expect { runner.upload_template('this is a fail test') }.to raise_error(TemplateUploadError)
      expect(WebMock).to have_requested(:put, 'http://127.0.0.1:8500/v1/kv/test-template-failure').with(:body => 'this is a fail test')
    end
  end
end
