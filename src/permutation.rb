require 'rngtools'

class Permutation
    def initialize(num_rounds, seed = nil)
        rng = RngTools.new(seed)
        @rounds = num_rounds.times.map{Round.new(rng)}
    end

    # Generates ZZT-OOP code that computes a pseudorandom permutation.
    # The input data shall be in counters x and y. The output will also be in these counters.
    # Assumes the temporary counter is 0. The temporary counter will be 0 after the code completes.
    def generate_code(counter_x: 'ammo', counter_y: 'gems', temp_counter: 'score', label_prefix: '')
        label_maker = LabelMaker.new(label_prefix)

        # Generate code for each round
        code = []
        full_counters = [counter_x, counter_y]
        empty_counter = temp_counter
        @rounds.each do |round|
            code << round.generate_code(full_counters[0], empty_counter, full_counters[1], label_maker)
            full_counters << empty_counter
            empty_counter = full_counters.shift
        end

        # After the permutation completes, temp_counter should be empty.
        # If this is not the case, we need to move data out of temp_counter.
        if temp_counter != empty_counter
            src_counter = temp_counter
            dest_counter = empty_counter
            # Instead of just moving the data, we move and bitwise negate.
            # This is fewer instructions, and it shouldn't significantly affect the permutation.
            15.times.reverse_each do |i|
                code << "#take #{src_counter} #{2**i} give #{dest_counter} #{2**i}\n"
            end
        end

        # Output code
        code.join
    end
end

class LabelMaker
    def initialize(label_prefix = '')
        @label_prefix = label_prefix
        @next_label = 'a'
    end

    def next_label
        retval = @label_prefix + @next_label
        @next_label = @next_label.next
        retval
    end
end

class Round
    def initialize(rng)
        # Pick a random number to be added to the counter-to-be-emptied before any other operations
        @round_constant = rng.random_number(2**15)

        # Generate patterns for tabulation hashing.
        # Each pattern corresponds to a bit position.
        # hash(value) = sum of patterns for which value has a 1 bit, mod 2^15
        @tabulation_hashing_patterns = rng.generate_balanced_numbers(15, 15)

        # Calculate how to rearrange the bits of value-to-be-moved.
        # Every bit changes location, and every bit will (with enough iterations) visit every location.
        @bit_permutation = rng.generate_cycle_map((0..14).to_a)
    end

    # Generates code that computes one round of a Feistel network:
    # - Move value-to-be-moved out of x_source, setting the counter to 0 in the process
    # - Add hash(value-to-be-moved) to counter y, mod 2^15
    # - Rearrange the bit order of value-to-be-moved
    # - Store the modified value-to-be-moved in x_destination
    def generate_code(x_source, x_destination, y, label_maker)
        code = []
        code << generate_wrapping_add_code(x_source, @round_constant)
        15.times.reverse_each do |src_bit|
            dest_bit = @bit_permutation[src_bit]
            label = label_maker.next_label
            code.push "#take #{x_source} #{2**src_bit} #{label}\n"
            code.push "#give #{x_destination} #{2**dest_bit}\n"
            code.push generate_wrapping_add_code(y, @tabulation_hashing_patterns[src_bit])
            code.push ":#{label}\n"
        end
        code.join
    end
end

# Generates code that adds value to counter, modulo 2**15
def generate_wrapping_add_code(counter, value)
    value %= 2**15
    return "" if value == 0
    "#take #{counter} #{2**15 - value} give #{counter} #{value}\n"
end
