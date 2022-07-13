# frozen_string_literal: true

module ViewComponent
  # This is a simpler version of {Capybara::Session}.
  #
  # It only includes {Capybara::Node::Finders}, {Capybara::Node::Matchers},
  # {#within} and {#within_element}. It is useful in that it does not require a
  # session, an application or a driver, but can still use Capybara's finders
  # and matchers on any string that contains HTML.
  class CapybaraSimpleSession
    # Most of the code in this class is shamelessly stolen from the
    # {Capybara::Session} class in the Capybara gem
    # (https://github.com/teamcapybara/capybara/blob/e704d00879fb1d1e1a0cc01e04c101bcd8af4a68/lib/capybara/session.rb#L38).

    NODE_METHODS = %i[
      all
      first
      text

      find
      find_all
      find_button
      find_by_id
      find_field
      find_link

      has_content?
      has_text?
      has_css?
      has_no_content?
      has_no_text?
      has_no_css?
      has_no_xpath?
      has_xpath?
      has_link?
      has_no_link?
      has_button?
      has_no_button?
      has_field?
      has_no_field?
      has_checked_field?
      has_unchecked_field?
      has_no_table?
      has_table?
      has_select?
      has_no_select?
      has_selector?
      has_no_selector?
      has_no_checked_field?
      has_no_unchecked_field?

      assert_selector
      assert_no_selector
      assert_all_of_selectors
      assert_none_of_selectors
      assert_any_of_selectors
      assert_text
      assert_no_text
    ].freeze

    private_constant :NODE_METHODS

    SESSION_METHODS = %i[within within_element within_fieldset within_table].freeze

    private_constant :SESSION_METHODS

    DSL_METHODS = (NODE_METHODS + SESSION_METHODS).freeze

    # Stolen from: https://github.com/teamcapybara/capybara/blob/e704d00879fb1d1e1a0cc01e04c101bcd8af4a68/lib/capybara/session.rb#L767-L774.
    NODE_METHODS.each do |method|
      if RUBY_VERSION >= "2.7"
        class_eval <<~METHOD, __FILE__, __LINE__ + 1
          def #{method}(...)
            current_scope.#{method}(...)
          end
        METHOD
      else
        define_method method do |*args, &block|
          current_scope.send(method, *args, &block)
        end
      end
    end

    # Initializes the receiver with the given string of HTML.
    #
    # @param html [String] the HTML to create the session out of
    def initialize(html)
      @document = Capybara::Node::Simple.new(html)
    end

    # (see Capybara::Session#within)
    def within(*args, **kw_args)
      new_scope = args.first.respond_to?(:to_capybara_node) ? args.first.to_capybara_node : find(*args, **kw_args)
      begin
        scopes.push(new_scope)
        yield if block_given?
      ensure
        scopes.pop
      end
    end

    # (see Capybara::Session#within_element)
    alias_method :within_element, :within

    # (see Capybara::Session#within_fieldset)
    def within_fieldset(locator, &block)
      within(:fieldset, locator, &block)
    end

    # (see Capybara::Session#within_table)
    def within_table(locator, &block)
      within(:table, locator, &block)
    end

    # (see Capybara::Node::Element#native)
    def native
      current_scope.native
    end

    private

    attr_reader :document

    def scopes
      @scopes ||= [nil]
    end

    def current_scope
      scopes.last.presence || document
    end
  end
end
