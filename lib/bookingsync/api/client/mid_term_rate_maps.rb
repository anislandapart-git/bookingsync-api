module BookingSync::API
  class Client
    module MidTermRateMaps
      def mid_term_rate_maps(options = {}, &block)
        paginate :mid_term_rate_maps, options, &block
      end
    end
  end
end
