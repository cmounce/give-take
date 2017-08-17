#!/usr/bin/env ruby
$LOAD_PATH.unshift __dir__ + '/src'
require 'permutation'

p = Permutation.new(3, ARGV[0])
puts p.generate_code
