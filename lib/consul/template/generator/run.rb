require 'consul/template/generator/ct'

module Consul
  module Template
    module Generator
      class CTRunner
        def run(comp_hash = nil)
          status, body, hash, uploaded_hash = nil, nil, nil, nil
          acquire_lock do
            @config.logger.debug "Attempting to render template: #{@config.template}"
            status, body, hash = render_template
            unless status == 0
              raise TemplateRenderError, "consul-template exited with on-zero exit status"
            end
            if body.nil? || body.empty?
              raise TemplateRenderError, "rendered template is nil or empty!"
            end
            @config.logger.debug "Template rendered..."
            if comp_hash.nil? || comp_hash != hash
              @config.logger.info "Change in template discovered, attempting to upload to key #{@config.template_key}"
              @config.logger.debug "Existing hash: #{comp_hash || 'nil'}, new hash: #{hash}"
              uploaded = upload_template(body)
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
