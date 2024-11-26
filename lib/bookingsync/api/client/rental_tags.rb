module BookingSync::API
  class Client
    module RentalTags
      def rental_tags(options = {}, &block)
        paginate :rental_tags, options, &block
      end
    end
  end
end
