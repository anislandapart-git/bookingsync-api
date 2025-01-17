module BookingSync::API
  class Client
    module RentalsTags
      def rentals_tags(options = {}, &block)
        paginate :rentals_tags, options, &block
      end

      def rentals_tag(id, options = {})
        get("rentals_tags/#{id}", options).pop
      end
    end
  end
end
