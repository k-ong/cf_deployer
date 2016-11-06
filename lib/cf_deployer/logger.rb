module CfDeployer
  class Log
    require 'log4r'
    include Log4r

    def self.debug(message)
      log.debug message
    end

    def self.info(message)
      log.info message
    end

    def self.error(message)
      log.error message
    end

    def self.log
      return @log if @log
      @log = Log4r::Logger.new('cf_deployer')
      # outputter = Outputter.stdout
      # outputter.formatter = PatternFormatter.new(:pattern => "%d [%l] (%c) %M", :date_pattern => "%y-%m-%d %H:%M:%S")
      @log.outputters = Outputter.stdout
      @log.level = Log4r::INFO
      @log
    end

    def self.level=(trace_level)
      trace_level ||= 'info'
      case trace_level.downcase
       when 'debug'
         log.level = Log4r::DEBUG
       else
         log.level = Log4r::INFO
      end
    end
  end
end
