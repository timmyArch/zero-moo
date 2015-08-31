require 'weakref'
require 'zero/moo/abstract_publisher'

module Zero
  module Moo

    class AbstractSubscriber < AbstractPublisher

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
      # @param topics [String,String,...] Only relevant for subscriber type
      #
      # @yield [message]
      # @yieldparam message [String]
      #
      # @return [void]
      #
      def on_receive *topics, &block
        listen!(topics: topics) unless thread.instance_of? Thread
        @receivers ||= []
        @receivers << block
      end
      
      ##
      # Is subscriber?
      #
      def subscriber?
        @type == ZMQ::SUB
      end

      ##
      # Is puller?
      #
      def puller?
        @type == ZMQ::PULL
      end

      protected
     
      ##
      # Validating socket type and reset [@type] instance variable
      #
      # @param allowed [Array<Symbol>] List of allowed socket types.
      #
      # @return [void]
      #
      def validate_socket_type allowed: [:all, :any]
        logger.debug "Validating SocketType: #{@type.inspect}"
        @type = case @type.to_s
                when "all" then ZMQ::SUB
                when "any" then ZMQ::PULL
                else
                  raise Object.const_get("#{self.class.name}::SocketTypeError"),
                    "Invalid socket type given. Requested any #{allowed.inspect}, "+
                    "got #{@type.inspect}"
                end
      end

      ##
      # Bind listener.
      #
      # @see on_receive
      #
      # @param topics [Array<String>] 
      #
      # @return [void]
      #
      def listen! topics: []
        @thread ||= Thread.new do
          @socket = context.socket(@type)
          error? socket.setsockopt(ZMQ::LINGER, 1), raize: SocketOptionError
          error? socket.connect("tcp://#{address}"), raize: ConnectError
          ObjectSpace.define_finalizer(WeakRef.new(self), proc{ stop! })
          if subscriber?
            topics.each do |x|
              error? @socket.setsockopt(ZMQ::SUBSCRIBE, x.to_s), raize: SocketOptionError
            end
          end
          loop do
            message = ''
            logger.debug "Waiting for message ... "
            if subscriber?
              topic = ''
              error? socket.recv_string(topic)
            end
            if puller? or socket.more_parts?
              error? socket.recv_string(message), raize: MessageError
              logger.debug "Received message: #{message}"
              handle_callbacks message
            end
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
