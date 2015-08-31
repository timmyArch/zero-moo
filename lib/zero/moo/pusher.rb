require 'zero/moo/abstract_publisher'

module Zero
  module Moo

    class Pusher < AbstractPublisher

      ##
      # @see AbstractPublisher#new
      #
      def initialize address: nil
        super address: address, type: :any
      end
     
    end
  
  end
end
