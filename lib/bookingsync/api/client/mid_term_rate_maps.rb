module BookingSync::API
  class Client
    module MidTermRateMaps
      def mid_term_rate_maps(options = {}, &block)
        return mid_term_rate_map(options[:id]) if options[:id]

        paginate :mid_term_rate_maps, options, &block
      end

      def mid_term_rate_map(mid_term_rate_map)
        get("mid_term_rate_maps/#{mid_term_rate_map}").pop
      end
    end
  end
end
