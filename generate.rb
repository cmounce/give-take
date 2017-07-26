#!/usr/bin/env ruby
require_relative 'codegen'

cg = CodeGenerator.new
puts cg.generate_round_code 'ammo', 'torches', 'gems'
