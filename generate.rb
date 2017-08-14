#!/usr/bin/env ruby
$LOAD_PATH.unshift __dir__ + '/src'
require 'permutation'

p = Permutation.new(3)
puts p.generate_code
