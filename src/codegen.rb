require 'rngtools'

class CodeGenerator
    def initialize(label_prefix = "")
        @label_prefix = label_prefix
        @next_label = 'a'
    end

    def next_label
        retval = @label_prefix + @next_label
        @next_label = @next_label.next
        retval
    end

    # Generates code that adds value to counter, modulo 2**15
    def generate_wrapping_add_code(counter, value)
        "#take #{counter} #{2**15 - value} give #{counter} #{value}\n"
    end

    # Generates code that computes one round of a Feistel network:
    # - Move value-to-be-moved out of x_source, setting the counter to 0 in the process
    # - Add hash(value-to-be-moved) to counter y, mod 2^15
    # - Rearrange the bit order of value-to-be-moved
    # - Store the modified value-to-be-moved in x_destination
    def generate_round_code(x_source, x_destination, y)
        # Generate patterns for tabulation hashing.
        # Each pattern corresponds to a bit position.
        # hash(value) = sum of patterns for which value has a 1 bit, mod 2^15
        tabulation_hashing_patterns = RngTools.generate_balanced_numbers(15, 15)

        # Calculate how to rearrange the bits of value-to-be-moved.
        # Every bit changes location, and every bit will (with enough iterations) visit every location.
        source_powers = (0..14).map{|x| 2**x}.reverse
        source_to_destination = RngTools.generate_cycle_map(source_powers)
        destination_powers = source_powers.map{|x| source_to_destination[x]}

        # Actually generate code
        code = []
        (0..14).each do |i|
            label = next_label
            code.push "#take #{x_source} #{source_powers[i]} #{label}\n"
            code.push "#give #{x_destination} #{destination_powers[i]}\n"
            code.push generate_wrapping_add_code(y, tabulation_hashing_patterns[i])
            code.push ":#{label}\n"
        end
        code.join
    end

    # Generates an array of code snippets that, when run, compute a multi-round permutation.
    # The input data shall be in counters x and y. The output will also be in these counters.
    # Assumes the temporary counter is 0. The temporary counter will be 0 after the code completes.
    # TODO: Perhaps instead of generating code directly, we should create a Permutation object that creates code?
    def generate_rounds_code(num_rounds, counter_x = 'ammo', counter_y = 'gems', temporary_counter = 'torches')
        is_counter_occupied = {
            counter_x => true,
            counter_y => true,
            temporary_counter => false
        };
        next_counter_to_move = counter_x

        # Generate code for rounds, round constants
        code = []
        num_rounds.times do
            # Figure out which counter values to move where.
            # There are three counters and two values: one of the counters is always empty.
            # Each round, we take the value that didn't move last time, and move it into the empty counter:
            #   counter_x:  A --+       +-> B       B --+
            #   counter_y:  B   |   B --+       +-> A   |   A -- . . .
            #   temporary:      +-> A       A --+       +-> B
            # If it helps, you can think of it as a kind of braid.
            source_counter = next_counter_to_move
            destination_counter = is_counter_occupied.keys.find{|c| !is_counter_occupied[c]}
            stationary_counter = is_counter_occupied.keys.find{|c| c != source_counter && c != destination_counter}
            next_counter_to_move = stationary_counter

            code.push generate_wrapping_add_code(source_counter, SecureRandom.random_number(2**15)) # round constant
            code.push generate_round_code(source_counter, destination_counter, stationary_counter)  # Feistel round
            is_counter_occupied[source_counter] = false
            is_counter_occupied[destination_counter] = true
        end

        # Make sure that x and y both have data, and that temporary is empty
        if is_counter_occupied[temporary_counter]
            source_counter = temporary_counter
            destination_counter = is_counter_occupied.keys.find{|c| !is_counter_occupied[c]}
            code.push "#give #{destination_counter} #{2**15 - 1}\n"
            powers = (0..14).map{|x| 2**x}.reverse
            powers.each do |power|
                code.push "#take #{source_counter} #{power} take #{destination_counter} #{power}\n"
            end
        end
        code.join
    end
end
