require 'zero/moo/publisher'

module Zero
  module Moo

    class Subscriber < Publisher

      class Error < Communicator::Error; end
      class MissingAddressError < Error; end
      class InvalidAddressError < Error; end
      class SocketOptionError < Error; end
      class SocketShutdownError < Error; end
      class MessageError < Error; end
      class ConnectError < Error; end

      undef :bind!
      undef :push!

      attr_reader :receivers
      private :receivers, :stop!

      ##
      # Add callbacks. The block will called with one 
      # argument. The message.
      #
      # @yield [message]
      # @yieldparam message [String]
      #
      # @return [void]
      #
      def on_receive &block
        listen! unless thread.instance_of? Thread
        unless @receivers 
          ObjectSpace.define_finalizer(self, proc{ stop! })
        end
        @receivers ||= []
        @receivers << block
      end

      private

      ##
      # Bind listener.
      #
      # @return [void]
      #
      def listen!
        @thread = Thread.new do
          @socket = context.socket(ZMQ::PULL)
          error? socket.setsockopt(ZMQ::LINGER, 1), raize: SocketOptionError
          error? socket.connect("tcp://#{address}"), raize: ConnectError
          loop do
            message = ''
            error? socket.recv_string(message), raize: MessageError
            handle_callbacks message
          end
        end
      end

      ##
      # Iterate over all callbacks and 
      # call them with given message.
      #
      # @return [void]
      #
      def handle_callbacks message
        receivers.to_a.each do |block|
          block.call message
        end
      end

    end

  end
end
