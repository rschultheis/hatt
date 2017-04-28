# include the hatt lib folder
# This is a nice way to test a gem
require 'bundler/setup'
Bundler.setup

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'

module TestConstants
  FullExampleFile = File.expand_path('../examples/full/hatt.yml', __FILE__)
  FullExampleDir = File.dirname FullExampleFile

  SingleHattFile = File.expand_path('../examples/simple_hattdsl/hattdsl.rb', __FILE__)
  HattFileWithARequire = File.expand_path('../examples/simple_hattdsl/hattdsl_file_with_a_require.rb', __FILE__)
  HattFileWithState = File.expand_path('../examples/simple_hattdsl/hattdsl_file_with_state.rb', __FILE__)

  SampleHattGlob = 'spec/examples/sample_hattdsl_collection/**/*_hattdsl.rb'.freeze
end
include TestConstants

# configure rspec basics
RSpec.configure do |config|
  # setting this to false ensure if we screw up a tag, nothing will run
  # and we'll know a tag is screwed up.
  config.run_all_when_everything_filtered = false
  config.expect_with(:rspec) { |c| c.syntax = %i[should expect] }
  config.mock_with(:rspec) { |mocks| mocks.syntax = %i[should receive] }
  # removing this bit of config as it will interfere with our custom tagging scheme
  # config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  # some tests use environment variables prefixed with HATT_
  # its best to just always clear any env vars with that prefix
  config.before(:each) do
    ENV.delete_if { |k| k =~ /^HATT_/ }
  end
end
