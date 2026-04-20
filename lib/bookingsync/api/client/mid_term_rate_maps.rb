module BookingSync::API
  class Client
    module MidTermRateMaps
      def mid_term_rate_maps(options = {}, &block)
        paginate :mid_term_rate_maps, options, &block
      end

      def mid_term_rate_map(options = {})
        get("mid_term_rate_maps/#{options.delete('rental_id')}").pop
      end
    end
  end
end
