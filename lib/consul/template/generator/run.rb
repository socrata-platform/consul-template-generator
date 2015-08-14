require 'diffy'
require 'consul/template/generator/ct'

module Consul
  module Template
    module Generator
      class CTRunner
        def run(template, template_key, comp_hash = nil, diff_changes = false)
          status, body, hash, uploaded_hash = nil, nil, nil, nil
          acquire_lock template_key do
            @config.logger.debug "Attempting to render template: #{template}"
            status, body, hash = render_template template
            unless status == 0
              raise TemplateRenderError, "consul-template exited with on-zero exit status"
            end
            if body.nil? || body.empty?
              raise TemplateRenderError, "rendered template is nil or empty!"
            end
            @config.logger.debug "Template rendered..."
            if comp_hash.nil? || comp_hash != hash
              @config.logger.info "Change in template discovered, attempting to upload to key #{template_key}"
              @config.logger.debug "Existing hash: #{comp_hash || 'nil'}, new hash: #{hash}"

              if diff_changes
                  @config.logger.info "Diffing templates..."
                  curr_template = retrieve_template template_key
                  diff = Diffy::Diff.new(curr_template, body, :include_diff_info => true, :context => 5).to_s(:text)
                  @config.logger.info diff
              end

              uploaded = upload_template(template_key, body)
              if uploaded
                @config.logger.info "New template uploaded..."
                uploaded_hash = hash
              else
                raise TemplateUploadError, "Template not uploaded!"
              end
            else
              @config.logger.info "No change in template, skipping upload..."
            end
          end
          return uploaded_hash
        end
      end
    end
  end
end
