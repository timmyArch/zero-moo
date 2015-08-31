require 'zero/moo/abstract_subscriber'

module Zero
  module Moo

    class Subscriber < AbstractSubscriber

      ##
      # @see AbstractPublisher#new
      #
      def initialize address: nil
        super address: address, type: :all
      end

    end

  end
end
