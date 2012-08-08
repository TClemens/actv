require 'faraday'
require 'actv/asset'
require 'actv/configurable'
require 'actv/error/forbidden'
require 'actv/error/not_found'
require 'actv/search_results'
require 'simple_oauth'

module ACTV
  # Wrapper for the ACTV REST API
  #
  # @note
  class Client
    include ACTV::Configurable
    
    # Initialized a new Client object
    # 
    # @param options [Hash]
    # @return[ACTV::Client]
    def initialize(options={})
      ACTV::Configurable.keys.each do |key|
        instance_variable_set("@#{key}", options[key] || ACTV.options[key])
      end
    end

    # Returns assets that match a specified query.
    #
    # @authentication_required No
    # @param q [String] A search term.
    # @param options [Hash] A customizable set of options.
    # @return [ACTV::SearchResults] Return assets that match a specified query with search metadata
    # @example Returns assets related to running
    #   ACTV.assets('running')
    #   ACTV.search('running')
    def assets(q, options={})
      response = get("/v2/search.json", options.merge(query: q))
          ACTV::SearchResults.from_response(response)
    end
    alias search assets

    # Sends a new direct message to the specified user from the authenticating user
    #
    # @authentication_required No
    # @return [ACTV::Asset] The requested asset.
    # @param id [String] An ssset ID.
    # @param options [Hash] A customizable set of options.
    # @example Return the asset with the id BA288960-2718-4B20-B380-8F939596B123
    #   ACTV.asset("BA288960-2718-4B20-B380-8F939596B123")
    def asset(id, options={})
      response = get("/v2/assets/#{id}.json", options)
      ACTV::Asset.from_response(response)
    end

    # Perform an HTTP GET request
    def get(path, params={}, options={})
      request(:get, path, params, options)
    end
    
    # Returns a Faraday::Connection object
    #
    # @return [Faraday::Connection]
    def connection
      @connection ||= Faraday.new(@endpoint, @connection_options.merge(:builder => @middleware))
    end
    
    # Perform an HTTP Request
    def request(method, path, params, options)
      uri = options[:endpoint] || @endpoint
      uri = URI(uri) unless uri.respond_to?(:host)
      uri += path
      request_headers = {}
      if self.credentials?
        # When posting a file, don't sign any params
        signature_params = if [:post, :put].include?(method.to_sym) && params.values.any?{|value| value.is_a?(File) || (value.is_a?(Hash) && (value[:io].is_a?(IO) || value[:io].is_a?(StringIO)))}
          {}
        else
          params
        end
        authorization = SimpleOAuth::Header.new(method, uri, signature_params, credentials)
        request_headers[:authorization] = authorization.to_s
      end
      connection.url_prefix = options[:endpoint] || @endpoint
      connection.run_request(method.to_sym, path, nil, request_headers) do |request|
        unless params.empty?
          case request.method
          when :post, :put
            request.body = params
          else
            request.params.update(params)
          end
        end
        yield request if block_given?
      end.env
    rescue Faraday::Error::ClientError
      raise ACTV::Error::ClientError
    end
    
    # Check whether credentials are present
    #
    # @return [Boolean]
    def credentials?
      credentials.values.all?
    end
    
  private
    
    # Credentials hash
    #
    # @return [Hash]
    def credentials
      {
        :consumer_key => @consumer_key,
        :consumer_secret => @consumer_secret,
        :token => @oauth_token,
        :token_secret => @oauth_token_secret,
      }
    end
    
  end
end