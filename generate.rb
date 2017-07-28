#!/usr/bin/env ruby
$LOAD_PATH.unshift __dir__ + '/src'
require 'codegen'

cg = CodeGenerator.new
puts cg.generate_round_code 'ammo', 'torches', 'gems'
