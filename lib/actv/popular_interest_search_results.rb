require 'actv/search_results'
require 'actv/popular_interest'

module ACTV
  class PopularInterestSearchResults < ACTV::SearchResults
    def results
      @results ||= Array(@attrs[:hits][:hits]).map do |article|
        ACTV::PopularInterest.fetch_or_create(article)
      end
    end
  end
end