# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # Checks for usages of `Hash#reject`, `Hash#select`, and `Hash#filter` methods
      # that can be replaced with `Hash#except` method.
      #
      # This cop should only be enabled on Ruby version 3.0 or higher.
      # (`Hash#except` was added in Ruby 3.0.)
      #
      # For safe detection, it is limited to commonly used string and symbol comparisons
      # when using `==` or `!=`.
      #
      # This cop doesn't check for `Hash#delete_if` and `Hash#keep_if` because they
      # modify the receiver.
      #
      # @safety
      #   This cop is unsafe because it cannot be guaranteed that the receiver
      #   is a `Hash` or responds to the replacement method.
      #
      # @example
      #
      #   # bad
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| k == :bar }
      #   {foo: 1, bar: 2, baz: 3}.select {|k, v| k != :bar }
      #   {foo: 1, bar: 2, baz: 3}.filter {|k, v| k != :bar }
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| k.eql?(:bar) }
      #
      #   # bad
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| %i[bar].include?(k) }
      #   {foo: 1, bar: 2, baz: 3}.select {|k, v| !%i[bar].include?(k) }
      #   {foo: 1, bar: 2, baz: 3}.filter {|k, v| !%i[bar].include?(k) }
      #
      #   # good
      #   {foo: 1, bar: 2, baz: 3}.except(:bar)
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: false (default)
      #
      #   # good
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| !%i[bar].exclude?(k) }
      #   {foo: 1, bar: 2, baz: 3}.select {|k, v| %i[bar].exclude?(k) }
      #
      #   # good
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| k.in?(%i[bar]) }
      #   {foo: 1, bar: 2, baz: 3}.select {|k, v| !k.in?(%i[bar]) }
      #
      # @example AllCops:ActiveSupportExtensionsEnabled: true
      #
      #   # bad
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| !%i[bar].exclude?(k) }
      #   {foo: 1, bar: 2, baz: 3}.select {|k, v| %i[bar].exclude?(k) }
      #
      #   # bad
      #   {foo: 1, bar: 2, baz: 3}.reject {|k, v| k.in?(%i[bar]) }
      #   {foo: 1, bar: 2, baz: 3}.select {|k, v| !k.in?(%i[bar]) }
      #
      #   # good
      #   {foo: 1, bar: 2, baz: 3}.except(:bar)
      #
      class HashExcept < Base
        include HashSubset
        extend TargetRubyVersion
        extend AutoCorrector

        minimum_target_ruby_version 3.0

        private

        def semantically_subset_method?(node)
          semantically_except_method?(node)
        end

        def preferred_method_name
          'except'
        end
      end
    end
  end
end
