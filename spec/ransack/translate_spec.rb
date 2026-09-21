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
  end
end
