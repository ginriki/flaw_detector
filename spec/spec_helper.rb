require 'rspec'
require 'flaw_detector'

RSpec.configure do |config|
  config.color_enabled = true
  config.formatter     = 'documentation'
end
