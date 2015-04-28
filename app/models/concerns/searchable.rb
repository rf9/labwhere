#TODO: improve the way the search method is done. At the moment it works by adding all the results together and then filtering.

module Searchable

  module Client

    extend ActiveSupport::Concern

    included do 
    end

    module ClassMethods

      def searchable_by(*attributes)
        define_singleton_method :search do |term|
          attributes.inject([]) do |result, attribute|
            result += where(arel_table[attribute].matches("%#{term}%"))
          end.uniq
        end
      end
    end

  end

  module Orchestrator

    extend ActiveSupport::Concern

    included do 
    end

    module ClassMethods

      def searches_in(*models)
        define_singleton_method :searchable_models do
          Hash[models.collect { |model| [model, model.to_s.classify.constantize] }]
        end
      end

    end

    def results
      @results ||= SearchResult.new.tap do |result|
        self.class.searchable_models.each do |k, v|
          result.add k, v.search(self.term)
        end
      end
    end

    class SearchResult
      include Enumerable
      attr_reader :results, :count
      delegate [], :empty?, to: :results

      def initialize
        @results = {}
        @count = 0
      end

      def each(&block)
        results.each(&block)
      end

      def add(k,v)
        @results[k] = v unless v.empty?
        @count += v.length
      end
    end
  end
  
end