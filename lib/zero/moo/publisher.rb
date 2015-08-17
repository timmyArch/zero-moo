require 'zero/moo/communicator'

module Zero
  module Moo

    class Publisher < Communicator

      class Error < Communicator::Error; end
      class MissingAddressError < Error; end
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
        kwargs[:type] = 1 
        raise Object.const_get("#{self.class.name}::MissingAddressError"), 
          ":address for bind was not given" unless @address
        validate_address
        validate_port
        super **kwargs
      end
     
      ##
      # Push a message to all subscribers.
      #
      def push! message
        bind! unless socket
        logger.debug "Push message: #{message}"
        error? socket.send_string(message), raize: MessageError
        message
      end
      
      private

      ##
      # Bind publisher to address.
      #
      # @return [void] 
      #
      def bind!
        @socket = context.socket(ZMQ::PUSH)
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
