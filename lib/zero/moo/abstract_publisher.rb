require 'zero/moo/communicator'
require 'weakref'

module Zero
  module Moo

    class Publisher < Communicator

      class Error < Communicator::Error; end
      class MissingAddressError < Error; end
      class SocketTypeError < Error; end
      class InvalidAddressError < Error; end
      class SocketOptionError < Error; end
      class SocketShutdownError < Error; end
      class MessageError < Error; end
      class BindError < Error; end

      attr_reader :address, :thread, :socket
      private :thread, :socket

      ##
      # Get publishing instance.
      #
      # @param address [String]
      #
      def initialize **kwargs
        @address = kwargs.delete(:address)
        @type = kwargs.delete(:type)
        kwargs[:type] = 1 
        raise Object.const_get("#{self.class.name}::MissingAddressError"), 
          ":address for bind was not given" unless @address
        validate_socket_type
        validate_address
        validate_port
        super **kwargs
      end
     
      ##
      # Push a message to all subscribers.
      #
      # @param topic [String,Array<String>] Only relevant for publisher type.
      #
      # @return [String] The given message
      #
      def push! message, topic: []
        topics = [topic].flatten
        bind! unless socket
        logger.debug "Push message: #{message}"
        if publisher?
          topics.each do |t|
            error? socket.send_string(t, ZMQ::SNDMORE)
            error? socket.send_string(message), raize: MessageError
          end
        elsif pusher?
          error? socket.send_string(message), raize: MessageError
        end
        message
      end
      
      ##
      # Is pusher?
      #
      def pusher?
        @type == ZMQ::PUSH
      end

      ##
      # Is publisher?
      #
      def publisher?
        @type == ZMQ::PUB
      end
      
      private

      ##
      # Bind publisher to address.
      #
      # @return [void] 
      #
      def bind!
        @socket = context.socket(@type)
        error? @socket.setsockopt(ZMQ::LINGER, 1), raize: SocketOptionError
        error? @socket.bind("tcp://#{address}"), raize: BindError
      end


      ##
      # Closing the publisher socket.
      #
      # @return [void]
      #
      def stop!
        logger.debug "terminating socket ..."
        if socket.respond_to? :close
          error? socket.close, raize: SocketShutdownError
        end
        if thread.instance_of? Thread
          thread.kill
        end
        @thread = nil
      end
      
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
                when "all" then ZMQ::PUB
                when "any" then ZMQ::PUSH
                else
                  raise Object.const_get("#{self.class.name}::SocketTypeError"),
                    "Invalid socket type given. Requested any #{allowed.inspect}, "+
                    "got #{@type.inspect}"
                end
      end


      protected

      ##
      # Validating Address/Host part of given address.
      #
      # @return [void]
      #
      def validate_address
        logger.debug "Validating address: #{@address.inspect}"
        address = @address.to_s[/[^:]+/]
        ip = IPAddr.new(address) rescue nil
        Socket.gethostbyname(address) unless ip 
      rescue SocketError => e
        raise Object.const_get("#{self.class.name}::InvalidAddressError"), 
          "Address: #{@address.inspect} is invalid. - #{e.message}"
      end

      ##
      # Validating port section in @address
      #
      # @return [void]
      #
      def validate_port
        clazz = Object.const_get(self.class.name+"::InvalidAddressError")
        logger.debug "Validating port: #{@address.inspect}"
        port = @address.to_s[/[^:]+$/].to_s[/\d+/]
        raise clazz, "Missing port in #{address}" if port.nil?
        unless (1024..65535).include? port.to_i
          raise clazz, 
            "Out of range. Port must be between 1024 and 65535"
        end
      end

    end
  
  end
end
