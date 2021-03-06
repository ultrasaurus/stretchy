require 'stretchy/filters/base'

module Stretchy
  module Filters
    class TermsFilter < Base

      attribute :field
      attribute :terms

      validations do
        rule :field, field: { required: true }
        rule :terms, type: {classes: [Numeric, Time, String, Symbol, TrueClass, FalseClass], array: true}
        rule :terms, :not_empty
      end

      def initialize(field, terms)
        @field = field
        @terms = Array(terms)
        validate!
      end

      def to_search
        {
          terms: {
            @field => @terms
          }
        }
      end
    end
  end
end
