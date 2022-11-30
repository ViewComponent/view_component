# frozen_string_literal: true

class InlineComponentPreview < ViewComponent::Preview
  def default
    render(InlineComponent.new)
  end

  def inside_form
  end

  def outside_form
  end

  def with_params(form_title: "Default Form Title")
    render_with_template(locals: {form_title: form_title})
  end

  def with_non_standard_template
    render_with_template(template: "non_standard_path/with_non_standard_template")
  end

  def with_haml
  end

  def without_template
    render_with_template
  end

  def with_several_options(form_title: "Another default")
    render_with_template(
      template: "non_standard_path/test_template",
      locals: {
        form_title: form_title,
        submit_text: "Send this form!"
      }
    )
  end
end
