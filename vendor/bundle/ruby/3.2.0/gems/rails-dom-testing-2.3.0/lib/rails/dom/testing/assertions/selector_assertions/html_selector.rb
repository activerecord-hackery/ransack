# frozen_string_literal: true

require "minitest"

require_relative "substitution_context"

module Rails
  module Dom
    module Testing
      module Assertions
        module SelectorAssertions
          class HTMLSelector # :nodoc:
            attr_reader :css_selector, :tests, :message

            include Minitest::Assertions

            def initialize(values, previous_selection = nil, refute: false, &root_fallback)
              @values = values
              @root = extract_root(previous_selection, root_fallback)
              extract_selectors
              @tests = extract_equality_tests(refute)
              @message = @values.shift

              if @message.is_a?(Hash)
                raise ArgumentError, "Last argument was a Hash, which would be used for the assertion message. You probably want this to be a String, or you have the wrong type of arguments."
              end

              if @values.shift
                raise ArgumentError, "Not expecting that last argument, you either have too many arguments, or they're the wrong type"
              end
            end

            def selecting_no_body? # :nodoc:
              # Nokogiri gives the document a body element. Which means we can't
              # run an assertion expecting there to not be a body.
              @selector == "body" && @tests[:count] == 0
            end

            def select
              filter @root.css(@selector, context)
            end

            private
              NO_STRIP = %w{pre script style textarea}

              mattr_reader(:context) { SubstitutionContext.new }

              def filter(matches)
                match_with = tests[:text] || tests[:html]
                return matches if matches.empty? || !match_with

                content_mismatch = nil
                text_matches = tests.has_key?(:text)
                html_matches = tests.has_key?(:html)
                regex_matching = match_with.is_a?(Regexp)

                remaining = matches.reject do |match|
                  # Preserve markup with to_s for html elements
                  content = text_matches ? match.text : match.inner_html

                  content.strip! unless NO_STRIP.include?(match.name)
                  content.delete_prefix!("\n") if text_matches && match.name == "textarea"
                  collapse_html_whitespace!(content) unless NO_STRIP.include?(match.name) || html_matches

                  next if regex_matching ? (content =~ match_with) : (content == match_with)
                  content_mismatch ||= diff(match_with, content)
                  true
                end

                @message ||= content_mismatch if remaining.empty?
                Nokogiri::XML::NodeSet.new(matches.document, remaining)
              end

              def extract_root(previous_selection, root_fallback)
                possible_root = @values.first

                if possible_root == nil
                  raise ArgumentError, "First argument is either selector or element " \
                    "to select, but nil found. Perhaps you called assert_dom with " \
                    "an element that does not exist?"
                elsif possible_root.respond_to?(:css)
                  @values.shift # remove the root, so selector is the first argument
                  possible_root
                elsif previous_selection
                  previous_selection
                else
                  root_fallback.call
                end
              end

              def extract_selectors
                selector = @values.shift

                unless selector.is_a? String
                  raise ArgumentError, "Expecting a selector as the first argument"
                end

                @css_selector = context.substitute!(selector, @values.dup, true)
                @selector     = context.substitute!(selector, @values)
              end

              def extract_equality_tests(refute)
                comparisons = {}
                case comparator = @values.shift
                when Hash
                  comparisons = comparator
                when String, Regexp
                  comparisons[:text] = comparator
                when Integer
                  comparisons[:count] = comparator
                when Range
                  comparisons[:minimum] = comparator.begin
                  comparisons[:maximum] = comparator.end
                when FalseClass
                  comparisons[:count] = 0
                when NilClass, TrueClass
                  comparisons[:minimum] = 1
                else
                  raise ArgumentError, "I don't understand what you're trying to match"
                end

                if refute
                  if comparisons[:count] || (comparisons[:minimum] && !comparator.nil?) || comparisons[:maximum]
                    raise ArgumentError, "Cannot use true, false, Integer, Range, :count, :minimum and :maximum when asserting that a selector does not match"
                  end

                  comparisons[:count] = 0
                end

                # By default we're looking for at least one match.
                if comparisons[:count]
                  comparisons[:minimum] = comparisons[:maximum] = comparisons[:count]
                else
                  comparisons[:minimum] ||= 1
                end

                if comparisons[:minimum] && comparisons[:maximum] && comparisons[:minimum] > comparisons[:maximum]
                  raise ArgumentError, "Range begin or :minimum cannot be greater than Range end or :maximum"
                end

                @strict = comparisons[:strict]

                comparisons
              end

              def collapse_html_whitespace!(text)
                text.gsub!(/\s+/, " ")
              end
          end
        end
      end
    end
  end
end
