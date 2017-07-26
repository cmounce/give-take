#!/usr/bin/env ruby
require_relative 'rngtools'

class CodeGenerator
    def initialize
        @next_label = 'a'
    end

    def next_label
        retval = @next_label
        @next_label = @next_label.next
        retval
    end

    # Generates code that adds value to counter, modulo 2**15
    def generate_wrapping_add_code(counter, value)
        "#take #{counter} #{2**15 - value} give #{counter} #{value}\n"
    end

    # Generates code that computes one round of the Feistel network:
    # - Move the value in counter x_source to x_destination
    # - Scramble the value in counter y based on x_source's previous value
    # - Permute the bits of counter x_destination
    def generate_round_code(x_source, x_destination, y)
        # Generate patterns for tabulation hashing.
        # The value in x will be hashed and added to y.
        tabulation_hashing_patterns = RngTools.generate_balanced_numbers(15, 15)

        # Calculate the permutation pattern for permuting x_destination.
        # After 1 permutation, no bit is where it used to be.
        # After 15 permutations, every bit has cycled through every position.
        source_powers = (0..14).map{|x| 2**x}.reverse
        source_to_destination = RngTools.generate_cycle_map(source_powers)
        destination_powers = source_powers.map{|x| source_to_destination[x]}

        code = ""
        (0..14).each do |i|
            label = next_label
            code += "#take #{x_source} #{source_powers[i]} #{label}\n"
            code += "#give #{x_destination} #{destination_powers[i]}\n"
            code += generate_wrapping_add_code(y, tabulation_hashing_patterns[i])
            code += ":#{label}\n"
        end
        code
    end
end

puts "Hello, world!"
