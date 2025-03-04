require "bookingsync/api/middleware/logger"
require "bookingsync/api/client/accounts"
require "bookingsync/api/client/amenities"
require "bookingsync/api/client/applications"
require "bookingsync/api/client/applications_periods_rentals"
require "bookingsync/api/client/attachments"
require "bookingsync/api/client/availabilities"
require "bookingsync/api/client/bathrooms"
require "bookingsync/api/client/bedrooms"
require "bookingsync/api/client/bookings"
require "bookingsync/api/client/booking_comments"
require "bookingsync/api/client/bookings_fees"
require "bookingsync/api/client/bookings_payments"
require "bookingsync/api/client/bookings_tags"
require "bookingsync/api/client/bookings_taxes"
require "bookingsync/api/client/change_overs"
require "bookingsync/api/client/clients"
require "bookingsync/api/client/contacts"
require "bookingsync/api/client/destinations"
require "bookingsync/api/client/fees"
require "bookingsync/api/client/host_reviews"
require "bookingsync/api/client/hosts"
require "bookingsync/api/client/inquiries"
require "bookingsync/api/client/living_rooms"
require "bookingsync/api/client/los_records"
require "bookingsync/api/client/nightly_rate_maps"
require "bookingsync/api/client/strict_bookings"
require "bookingsync/api/client/periods"
require "bookingsync/api/client/payments"
require "bookingsync/api/client/payment_gateways"
require "bookingsync/api/client/preferences_general_settings"
require "bookingsync/api/client/photos"
require "bookingsync/api/client/rates"
require "bookingsync/api/client/rates_rules"
require "bookingsync/api/client/rates_tables"
require "bookingsync/api/client/rentals"
require "bookingsync/api/client/rentals_fees"
require "bookingsync/api/client/rentals_amenities"
require "bookingsync/api/client/rental_agreements"
require "bookingsync/api/client/rental_cancelation_policies"
require "bookingsync/api/client/rental_cancelation_policy_items"
require "bookingsync/api/client/rentals_contents_overrides"
require "bookingsync/api/client/rentals_tags"
require "bookingsync/api/client/rental_urls"
require "bookingsync/api/client/review_replies"
require "bookingsync/api/client/reviews"
require "bookingsync/api/client/seasons"
require "bookingsync/api/client/special_offers"
require "bookingsync/api/client/sources"
require "bookingsync/api/client/taxes"
require "bookingsync/api/client/conversations"
require "bookingsync/api/client/messages"
require "bookingsync/api/client/participants"
require "bookingsync/api/error"
require "bookingsync/api/relation"
require "bookingsync/api/response"
require "bookingsync/api/resource"
require "bookingsync/api/serializer"
require "logger"
require "addressable/template"

module BookingSync::API
  class Client
    extend Forwardable
    include BookingSync::API::Client::Accounts
    include BookingSync::API::Client::Amenities
    include BookingSync::API::Client::Applications
    include BookingSync::API::Client::ApplicationsPeriodsRentals
    include BookingSync::API::Client::Attachments
    include BookingSync::API::Client::Availabilities
    include BookingSync::API::Client::Bathrooms
    include BookingSync::API::Client::Bedrooms
    include BookingSync::API::Client::Bookings
    include BookingSync::API::Client::BookingComments
    include BookingSync::API::Client::BookingsFees
    include BookingSync::API::Client::BookingsPayments
    include BookingSync::API::Client::BookingsTags
    include BookingSync::API::Client::BookingsTaxes
    include BookingSync::API::Client::ChangeOvers
    include BookingSync::API::Client::Conversations
    include BookingSync::API::Client::Clients
    include BookingSync::API::Client::Contacts
    include BookingSync::API::Client::Destinations
    include BookingSync::API::Client::Fees
    include BookingSync::API::Client::Hosts
    include BookingSync::API::Client::HostReviews
    include BookingSync::API::Client::Inquiries
    include BookingSync::API::Client::LivingRooms
    include BookingSync::API::Client::LosRecords
    include BookingSync::API::Client::Messages
    include BookingSync::API::Client::NightlyRateMaps
    include BookingSync::API::Client::StrictBookings
    include BookingSync::API::Client::Participants
    include BookingSync::API::Client::Periods
    include BookingSync::API::Client::Payments
    include BookingSync::API::Client::PaymentGateways
    include BookingSync::API::Client::PreferencesGeneralSettings
    include BookingSync::API::Client::Photos
    include BookingSync::API::Client::Rates
    include BookingSync::API::Client::RatesRules
    include BookingSync::API::Client::RatesTables
    include BookingSync::API::Client::Rentals
    include BookingSync::API::Client::RentalsFees
    include BookingSync::API::Client::RentalsAmenities
    include BookingSync::API::Client::RentalAgreements
    include BookingSync::API::Client::RentalCancelationPolicies
    include BookingSync::API::Client::RentalCancelationPolicyItems
    include BookingSync::API::Client::RentalsContentsOverrides
    include BookingSync::API::Client::RentalsTags
    include BookingSync::API::Client::RentalUrls
    include BookingSync::API::Client::ReviewReplies
    include BookingSync::API::Client::Reviews
    include BookingSync::API::Client::Seasons
    include BookingSync::API::Client::SpecialOffers
    include BookingSync::API::Client::Sources
    include BookingSync::API::Client::Taxes

    MEDIA_TYPE = "application/vnd.api+json".freeze

    attr_reader :token, :logger, :pagination_first_response, :last_response

    def_delegator :@instrumenter, :instrument

    # Initialize new Client
    #
    # @param token [String] OAuth token
    # @param options [Hash]
    # @option options [String] base_url: Base URL to BookingSync site
    # @option options [Logger] logger: Logger where headers and body of every
    #   request and response will be logged.
    # @option options [Module] instrumenter: A module that responds to
    #   instrument, usually ActiveSupport::Notifications.
    # @return [BookingSync::API::Client] New BookingSync API client
    def initialize(token, options = {})
      @token = token
      @logger = options[:logger] || default_logger
      @instrumenter = options[:instrumenter] || NoopInstrumenter
      @base_url = options[:base_url]
      @serializer = Serializer.new
      @conn = build_connection
      @conn.headers[:accept] = MEDIA_TYPE
      @conn.headers[:content_type] = MEDIA_TYPE
      @conn.headers[:user_agent] = user_agent
      @conn.url_prefix = api_endpoint
      yield @conn if block_given?
    end

    # Make a HTTP GET request
    #
    # @param path [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Query params for the request
    # @return [Array<BookingSync::API::Resource>] Array of resources.
    def get(path, options = {})
      request :get, path, query: options
    end

    # Make a HTTP POST request
    #
    # @param path [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body params for the request
    # @return [Array<BookingSync::API::Resource>]
    def post(path, options = {})
      request :post, path, options
    end

    # Make a HTTP PUT request
    #
    # @param path [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body params for the request
    # @return [Array<BookingSync::API::Resource>]
    def put(path, options = {})
      request :put, path, options
    end

    # Make a HTTP PATCH request
    #
    # @param path [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body params for the request
    # @return [Array<BookingSync::API::Resource>]
    def patch(path, options = {})
      request :patch, path, options
    end

    # Make a HTTP DELETE request
    #
    # @param path [String] The path, relative to {#api_endpoint}
    # @param options [Hash] Body params for the request
    # @return [Array<BookingSync::API::Resource>]
    def delete(path, options = {})
      request :delete, path, options
    end

    # Return API endpoint
    #
    # @return [String] URL to API endpoint
    def api_endpoint
      URI.join(base_url, "api/v3").to_s
    end

    # Encode an object to a string for the API request.
    #
    # @param data [Object] The Hash or Resource that is being sent.
    # @return [String] Object encoded into JSON string
    def encode_body(data)
      @serializer.encode(data)
    end

    # Decode a String response body to a Resource.
    #
    # @param str [String] The String body from the response.
    # @return [Object] Object resource
    def decode_body(str)
      @serializer.decode(str)
    end

    # Make a HTTP request to a path and returns an Array of Resources
    #
    # @param method [Symbol] HTTP verb to use.
    # @param path [String] The path, relative to {#api_endpoint}.
    # @param data [Hash] Data to be send in the request's body
    #   it can include query: key with requests params for GET requests
    # @param options [Hash] A customizable set of request options.
    # @return [Array<BookingSync::API::Resource>] Array of resources.
    def request(method, path, data = nil, options = nil)
      instrument("request.bookingsync_api", method: method, path: path) do
        response = call(method, path, data, options)
        response.respond_to?(:resources) ? response.resources : response
      end
    end

    # Make a HTTP GET or POST request to a path with pagination support.
    #
    # @param options [Hash]
    # @option options [Integer] per_page: Number of resources per page
    # @option options [Integer] page: Number of page to return
    # @option options [Boolean] auto_paginate: If true, all resources will
    #   be returned. It makes multiple requestes underneath and joins the results.
    #
    # @yieldreturn [Array<BookingSync::API::Resource>] Batch of resources
    # @return [Array<BookingSync::API::Resource>] Batch of resources
    def paginate(path, options = {}, &block)
      instrument("paginate.bookingsync_api", path: path) do
        request_settings = {
          auto_paginate: options.delete(:auto_paginate),
          request_method: options.delete(:request_method) || :get
        }

        data = if block_given?
                 fetch_with_block(path, options, request_settings, &block)
               else
                 fetch_with_paginate(path, options, request_settings)
               end

        data
      end
    end

    # Make a HTTP request to given path and returns Response object.
    #
    # @param method [Symbol] HTTP verb to use.
    # @param path [String] The path, relative to {#api_endpoint}.
    # @param data [Hash] Data to be send in the request's body
    #   it can include query: key with requests params for GET requests
    # @param options [Hash] A customizable set of request options.
    # @return [BookingSync::API::Response] A Response object.
    def call(method, path, data = nil, options = nil)
      instrument("call.bookingsync_api", method: method, path: path) do
        if [:get, :head].include?(method)
          options = data
          data = {}
        end
        options ||= {}
        options[:headers] ||= {}
        options[:headers]["Authorization"] = "Bearer #{token}"

        if options.has_key?(:query)
          if options[:query].has_key?(:ids)
            ids = Array(options[:query].delete(:ids)).join(",")
            path = "#{path}/#{ids}"
          end
          options[:query].keys.each do |key|
            if options[:query][key].is_a?(Array)
              options[:query][key] = options[:query][key].join(",")
            end
          end
        end

        url = expand_url(path, options[:uri])
        res = @conn.send(method, url) do |req|
          if data
            req.body = data.is_a?(String) ? data : encode_body(data)
          end
          if params = options[:query]
            req.params.update params
          end
          req.headers.update options[:headers]
        end
        handle_response(res)
      end
    end

    # Yields client with temporarily modified headers.
    #
    # @param extra_headers [Hash] Additional headers added to next request.
    # @yieldreturn [BookingSync::API::Client] Client with modified default headers.
    # @return [Array<BookingSync::API::Resource>|BookingSync::API::Resource|String|Object] Client response
    def with_headers(extra_headers = {}, &block)
      original_headers = @conn.headers.dup
      @conn.headers.merge!(extra_headers)
      result = yield self
      @conn.headers = original_headers
      result
    end

    private

    def build_connection
      Faraday.new(**faraday_options) do |f|
        f.use :logger, logger
        f.adapter :net_http_persistent
      end
    end

    def faraday_options
      { ssl: { verify: verify_ssl? } }
    end

    # Return BookingSync base URL. Default is https://www.bookingsync.com
    # it can be altered via ENV variable BOOKINGSYNC_URL which
    # is useful in specs when recording vcr cassettes. In also can be passed
    # as :base_url option when initializing the Client object
    #
    # @return [String] Base URL to BookingSync
    def base_url
      @base_url || ENV.fetch("BOOKINGSYNC_URL", "https://www.bookingsync.com")
    end

    # Return true if SSL cert should be verified
    # By default is true, can be changed to false using
    # env variable VERIFY_SSL
    #
    # @return [Boolean] true if SSL needs to be verified
    # false otherwise
    def verify_ssl?
      ENV["BOOKINGSYNC_VERIFY_SSL"] != "false"
    end

    # Expand an URL template into a full URL
    #
    # @param url [String|Addressable::Template] - An URL to be expanded
    # @param options [Hash] - Variables which will be used to expand
    # @return [String] - Expanded URL
    def expand_url(url, options = nil)
      tpl = url.respond_to?(:expand) ? url : ::Addressable::Template.new(url.to_s)
      tpl.expand(options || {}).to_s
    end

    # Process faraday response.
    #
    # @param faraday_response [Faraday::Response] - A response to process
    # @raise [BookingSync::API::Unauthorized] - On unauthorized user
    # @raise [BookingSync::API::UnprocessableEntity] - On validations error
    # @return [BookingSync::API::Response|NilClass]
    def handle_response(faraday_response)
      @last_response = response = Response.new(self, faraday_response)
      case response.status
      when 204 then nil # destroy/cancel
      when 200..299 then response
      when 401 then raise Unauthorized.new(response)
      when 403 then raise Forbidden.new(response)
      when 404 then raise NotFound.new(response)
      when 422 then raise UnprocessableEntity.new(response)
      when 429 then raise RateLimitExceeded.new(response)
      else raise UnsupportedResponse.new(response)
      end
    end

    def debug?
      ENV["BOOKINGSYNC_API_DEBUG"] == "true"
    end

    # Return default logger. By default we don't log anywhere.
    # If we are in debug mode, we log everything to STDOUT.
    #
    # @return [Logger] Logger where faraday middleware will log requests and
    #   responses.
    def default_logger
      Logger.new(debug? ? STDOUT : nil)
    end

    # Return user agent with gem version, can be logged in API.
    def user_agent
      "BookingSync API gem v#{BookingSync::API::VERSION}"
    end

    # Default instrumenter which does nothing.
    module NoopInstrumenter
      def self.instrument(name, payload = {})
        yield payload if block_given?
      end
    end

    def fetch_with_paginate(path, options, request_settings, data = [], response = nil)
      response ||= initial_call(path, options, request_settings)
      data.concat(response.resources)
      if response.relations[:next] && request_settings[:auto_paginate]
        fetch_with_paginate(path, options, request_settings, data,
                            next_page(response, request_settings))
      else
        data
      end
    end

    def fetch_with_block(path, options, request_settings, response = nil, &block)
      response ||= initial_call(path, options, request_settings)
      block.call(response.resources)
      return unless response.relations[:next]

      fetch_with_block(path, options, request_settings, next_page(response, request_settings),
                       &block)
    end

    def initial_call(path, options, request_settings)
      request_method = request_settings[:request_method]
      response = if request_method == :get
                   call(request_method, path, query: options)
                 else
                   call(request_method, path, options)
                 end
      @pagination_first_response = response
    end

    def next_page(response, request_settings)
      response.relations[:next].call({}, { method: request_settings[:request_method] })
    end

    def reject_blank_values(array)
      array.reject { |value| value.nil? || value == "" }
    end
  end
end
