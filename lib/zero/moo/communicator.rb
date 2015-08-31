require 'zero/moo'
require 'weakref'
require 'ffi-rzmq'

Thread.abort_on_exception

module Zero
  module Moo

    class Communicator

      class Error < Zero::Moo::Error; end
      class ContextError < Error; end
      class ArgumentError < Error; end

      attr_reader :context

      ##
      # Instanziate ZeroMQ context.
      #
      # @params type [Fixnum] ZMQ::Context type
      #
      def initialize type: 1
        logger.debug "Creating ZMQ::Context type: #{type.inspect}"
        @context = ZMQ::Context.create(type)
        raise ContextError, "Zmq context couldn't created." unless @context
        logger.debug "Add finalizer for context termination."
        ObjectSpace.define_finalizer(WeakRef.new(self), 
                                     proc{
          logger.debug "closing socket ..." if @socket
          error?(@socket.close) if @socket.respond_to(:close)
          logger.debug "terminating context ..."
          self.context.terminate if self.context
        })
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
      

      protected

      ##
      # Get logger instance.
      #
      # @return [Zero::Moo::Logger]
      #
      def logger
        unless @logger
          @logger = Logger.dup
          @logger.instance_variable_set(:@progname, 
                                        "#{self.class.name} ##{self.__id__}")
        end
        @logger
      end

      ##
      # Checking return codes.
      #
      # @param rc [Fixnum] Return code
      # @params raize [Class]
      #
      # @return [TrueClass, FalseClass] 
      #   If true, an error has ocoured.
      #
      def error?(rc, raize: nil)
        if raize and raize.is_a?(Class) and 
          not raize.ancestors.include?(StandardError)
          raise ArgumentError, ":raize must contain a raisable class"
        end
        logger.debug "Checking error code ..."
        if ZMQ::Util.resultcode_ok?(rc)
          false
        else
          err = <<-ERR.split.join(' ') 
            Operation failed, errno [#{ZMQ::Util.errno}] 
            description [#{ZMQ::Util.error_string}]
          ERR
          logger.error err
          caller(1).each { |callstack| logger.error(callstack) }
          raise raize, err if raize
          true
        end
      end

    end

  end
end
