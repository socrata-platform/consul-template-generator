require 'spec_helper'

require 'consul/template/generator'

include Consul::Template::Generator

describe 'Consul::Template::Generator::CTRunner' '#run' do
  before do
    @runner = Consul::Template::Generator::CTRunner.new 'test-session'
    allow(@runner).to receive(:acquire_lock).and_yield
  end

  context 'run' do
    it 'handles a clean run' do
      exp_hash = 'bbf9afe7431caf5f89a608bc31e8d822'
      expect(@runner).to receive(:render_template).with(no_args).and_return([0, 'test body', exp_hash])
      expect(@runner).to receive(:upload_template).with('test body').and_return(true)
      hash = @runner.run
      expect(hash).to eql(exp_hash)
    end

    it "doesn't upload unchanged template" do
      exp_hash = 'bbf9afe7431caf5f89a608bc31e8d822'
      expect(@runner).to receive(:render_template).with(no_args).and_return([0, 'test body', exp_hash])
      expect(@runner).not_to receive(:upload_template)
      hash = @runner.run exp_hash
      expect(hash).to be_nil
    end

    it 'handles non-zero exit status' do
      expect(@runner).to receive(:render_template).with(no_args).and_return([1, 'not used', 'not used'])
      expect(@runner).not_to receive(:upload_template)
      expect { @runner.run }.to raise_exception(TemplateRenderError)
    end

    it 'handles empty rendered template' do
      expect(@runner).to receive(:render_template).with(no_args).and_return([0, '', 'not used'])
      expect(@runner).not_to receive(:upload_template)
      expect { @runner.run }.to raise_exception(TemplateRenderError)
    end

    it 'handles bad return from upload_template' do
      exp_hash = 'bbf9afe7431caf5f89a608bc31e8d822'
      expect(@runner).to receive(:render_template).with(no_args).and_return([0, 'test body', exp_hash])
      expect(@runner).to receive(:upload_template).with('test body').and_return(false)
      expect { @runner.run }.to raise_exception(TemplateUploadError)
    end
  end
end
