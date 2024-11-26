module BookingSync::API
  class Client
    module RentalTags
      def rentals_tags(options = {}, &block)
        paginate :rentals_tags, options, &block
      end
    end
  end
end
