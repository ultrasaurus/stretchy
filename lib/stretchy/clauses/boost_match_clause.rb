require 'stretchy/clauses/boost_clause'

module Stretchy
  module Clauses
      #
      # Boost documents that match a free-text query. Most
      # options will be passed into {#initialize}, but you
      # can also chain `.not` onto it. Calling `.where` or
      # `.match` from here will apply filters (*not boosts*)
      # and return to the base state
      #
      # @author [atevans]
      #
    class BoostMatchClause < BoostClause

      delegate [:range, :geo] => :where

      #
      # Switches to inverse context, and applies filters as inverse
      # options (ie, documents that *do not* match the query will
      # be boosted)
      #
      # @overload not(params)
      #   @param [String] String that must not match anywhere in the document
      #
      # @overload not(params)
      #   @param params [Hash] Fields and values that should not match in the document
      #
      # @return [BoostMatchClause] Query with inverse matching boost function applied
      def not(params = {})
        @inverse = true
        match_function(hashify_params(params))
      end

      #
      # Boosts documents that are returned by a Match query.
      #
      # @param [Hash] Parameters for the match query. See {MatchClause#match}
      # @param [Hash] Options for Stretchy to determine behavior of this boost
      #
      # @return [BoostMatchClause] Query with boost match applied
      def boost_match(params = {}, options = {})
        match_function(hashify_params(params), options)
      end

      #
      # Boosts documents according to how closely they match a given phrase.
      # This acts similarly to {MatchClause#fulltext}, but only adds a boost,
      # so it will not interfere with the query. For example, it will not
      # filter out documents that don't match at least one term.
      #
      # @param [Hash] Parameters for the match query. See {MatchClause#match}
      # @param [Hash] Options for Stretchy to determine behavior of this boost
      #
      # @return [Base] Query with boost match applied
      def fulltext(params = {}, options = {})
        _params = hashify_params(params)
        weight = _params.delete(:weight) || options[:weight]
        options[:min]  ||= MatchClause::FULLTEXT_MIN
        options[:slop] ||= MatchClause::FULLTEXT_SLOP
        options[:type] ||= Queries::MatchQuery::MATCH_TYPES.first
        clause = MatchClause.new.match(_params, options)
        boost  = clause.to_boost(weight)
        base.boost_builder.add_boost(boost) if boost
        Base.new(base)
      end

      #
      # Boosts documents using a query with arbitrary json passed to the
      # method. See {MatchClause#query}.
      #
      # @param [Hash] Arbitrary json to use as a query
      # @param [Hash] Options for Stretchy to determine behavior of this boost
      #
      # @return [Base] Query with arbitrary json query boost added
      def query(params = {}, options = {})
        weight = params.delete(:weight) || options[:weight]
        clause = MatchClause.new.query(params, options)
        boost = clause.to_boost(weight)
        base.boost_builder.add_boost(boost) if boost
        Base.new(base)
      end

      #
      # Returns to the base context; filters passed here
      # will be used to filter documents.
      #
      # @example Returning to base context
      #   query.boost.match('string').where(other_field: 64)
      #
      # @example Staying in boost context
      #   query.boost.match('string').boost.where(other_field: 99)
      #
      # @see {WhereClause#initialize}
      #
      # @return [WhereClause] Query with where clause applied
      def where(*args)
        WhereClause.new(base).where(*args)
      end

      #
      # Returns to the base context. Queries passed here
      # will be used to filter documents.
      #
      # @example Returning to base context
      #   query.boost.match(message: 'curse word').match('username')
      #
      # @example Staying in boost context
      #   query.boost.match(message: 'happy word').boost.match('love')
      #
      # @see {MatchClause#initialize}
      #
      # @return [MatchClause] Base context with match queries applied
      def match(*args)
        MatchClause.new(base).match(*args)
      end

      private

        def match_function(params = {}, options = {})
          weight = hashify_params(params).delete(:weight) || options[:weight]
          clause = MatchClause.new.match(params, options)
          boost  = clause.to_boost(weight)
          base.boost_builder.add_boost(boost) if boost
          self
        end

    end
  end
end
