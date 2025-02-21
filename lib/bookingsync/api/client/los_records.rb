module BookingSync::API
  class Client
    module LosRecords
      def lost_records(options = {}, &block)
        paginate :los_records, options, &block
      end
    end
  end
end
