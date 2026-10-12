require 'spec_helper'

module Ransack
  describe Translate do
    describe '.attribute' do
      it 'translate namespaced attribute like AR does' do
        ar_translation = ::Namespace::Article.human_attribute_name(:title)
        ransack_translation = Ransack::Translate.attribute(
          :title,
          context: ::Namespace::Article.ransack.context
          )
        expect(ransack_translation).to eq ar_translation
      end

      # The association path was walked shortest-segment-first, so `notable`
      # matched before its `_of_Person_type` suffix was seen and the
      # polymorphic reflection was asked for a class (#1557).
      it 'translates an attribute through a polymorphic association' do
        translation = Ransack::Translate.attribute(
          'notable_of_Person_type_name_eq',
          context: Note.ransack.context
          )
        expect(translation).to eq 'Full Name equals'
      end
    end

    describe '.predicate' do
      # A predicate with no entry under `ransack.predicates` falls back to its
      # own key, so a form built from `Translate.predicate` offers `i_cont` or
      # `length_gteq` as the label a user has to choose from.
      #
      # The base names are read from the constants rather than from
      # `Predicate.names` because specs elsewhere add predicates of their own to
      # the registry and never remove them. Whether a base predicate has
      # `_any` / `_all` compounds is asked of the registry, because
      # `add_predicate` deletes the `:compounds` option from the constant while
      # reading it.
      it 'translates every predicate Ransack ships, in every locale it ships' do
        missing = shipped_locales.flat_map do |locale|
          shipped_predicates
            .reject { |name| I18n.exists?(:"ransack.predicates.#{name}", locale) }
            .map { |name| "#{locale}.#{name}" }
        end

        expect(missing).to eq []
      end

      def shipped_predicates
        base = Constants::AREL_PREDICATES +
               Constants::DERIVED_PREDICATES.map(&:first)

        base.flat_map do |name|
          compounds = Constants::SUFFIXES
            .map { |suffix| name + suffix }
            .select { |compound| Predicate.named(compound) }

          [name, *compounds]
        end
      end

      def shipped_locales
        Dir[File.expand_path('../../lib/ransack/locale/*.yml', __dir__)]
          .map { |path| File.basename(path, '.yml').to_sym }
          .sort
      end
    end
  end
end
