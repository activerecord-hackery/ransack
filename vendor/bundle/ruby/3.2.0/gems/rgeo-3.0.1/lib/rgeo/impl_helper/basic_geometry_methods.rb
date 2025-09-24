# frozen_string_literal: true

# -----------------------------------------------------------------------------
#
# Basic methods used by geometry objects
#
# -----------------------------------------------------------------------------

module RGeo
  module ImplHelper # :nodoc:
    module BasicGeometryMethods # :nodoc:
      include Feature::Instance

      attr_accessor :factory

      def inspect # :nodoc:
        "#<#{self.class}:0x#{object_id.to_s(16)} #{as_text.inspect}>"
      end

      def to_s # :nodoc:
        as_text
      end

      def as_text
        @factory.generate_wkt(self)
      end

      def as_binary
        @factory.generate_wkb(self)
      end

      def marshal_dump # :nodoc:
        [@factory, @factory.marshal_wkb_generator.generate(self)]
      end

      def marshal_load(data)  # :nodoc:
        copy_state_from(data[0].marshal_wkb_parser.parse(data[1]))
      end

      def encode_with(coder)  # :nodoc:
        coder["factory"] = @factory
        coder["wkt"] = @factory.psych_wkt_generator.generate(self)
      end

      def init_with(coder) # :nodoc:
        copy_state_from(coder["factory"].psych_wkt_parser.parse(coder["wkt"]))
      end

      private

      def copy_state_from(obj)
        @factory = obj.factory
      end

      def init_geometry; end
    end
  end
end
