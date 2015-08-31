require 'zero/moo/abstract_publisher'

module Zero
  module Moo

    class Publisher < AbstractPublisher

      ##
      # @see AbstractPublisher#new
      #
      def initialize address: nil
        super address: address, type: :all
      end
     
    end
  
  end
end
