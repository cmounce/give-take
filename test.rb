#!/usr/bin/env ruby
$LOAD_PATH.unshift __dir__ + '/src'
Dir.glob(__dir__ + '/test/*.rb').each {|test_file| require_relative test_file}
