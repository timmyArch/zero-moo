require 'zero/moo/abstract_subscriber'

module Zero
  module Moo

    class Puller < AbstractSubscriber

      ##
      # @see AbstractPublisher#new
      #
      def initialize address: nil
        super address: address, type: :any
      end

    end

  end
end
