require 'syslog/logger'

module Zero
  module Moo

    #Logger = Syslog::Logger.new("Zero::Moo")
    Logger = Logger.new(STDOUT)

  end
end
