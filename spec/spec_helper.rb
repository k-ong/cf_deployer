require_relative '../lib/cf_deployer'
Dir.glob("#{File.dirname File.absolute_path(__FILE__)}/fakes/*.rb") { |file| require file }

CfDeployer::Log.log.outputters = nil

RSPEC_LOG = Log4r::Logger.new('cf_deployer')
RSPEC_LOG.outputters = Log4r::Outputter.stdout
RSPEC_LOG.level = Log4r::WARN

if ENV['DEBUG']
  RSPEC_LOG.level = Log4r::DEBUG
  Aws.config.update(:logger => RSPEC_LOG)
end

def puts *args

end

def ignore_errors
  yield
rescue => e
  RSPEC_LOG.debug "Intentionally ignoring error: #{e.message}"
end
