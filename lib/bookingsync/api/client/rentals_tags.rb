module BookingSync::API
  class Client
    module RentalsTags
      def rentals_tags(options = {}, &block)
        paginate :rentals_tags, options, &block
      end
    end
  end
end
