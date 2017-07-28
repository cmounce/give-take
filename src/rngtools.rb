require 'securerandom'

class RngTools
    # Shuffles the given array using SecureRandom.
    # This is overkill, but so is this whole project, so why not?
    def self.secure_shuffle(a)
        (0..a.length - 1).each do |i|
            j = i + SecureRandom.random_number(a.length - i)
            a[i], a[j] = a[j], a[i]
        end
    end

    # Returns a random int that, in binary, has the specified counts of 1s and 0s.
    def self.generate_constrained_number(num_ones, num_zeros)
        bits = [1]*num_ones + [0]*num_zeros
        self.secure_shuffle(bits)
        bits.reduce(0){|acc, bit| acc*2 + bit}
    end

    # Returns an array of random ints, each one bits_per_number long.
    # Each int will have half of its bits set to 1 and half set to 0.
    # If bits_per_number is odd, this function will generate ints that
    # are as close as possible to having an equal number of 1s and 0s.
    def self.generate_balanced_numbers(num_numbers, bits_per_number)
        if bits_per_number % 2 == 0
            hamming_weight = bits_per_number/2
            weights = [hamming_weight]*num_numbers
        else
            min_hamming_weight = bits_per_number/2
            max_hamming_weight = min_hamming_weight + 1
            num_pairs = (num_numbers/2.0).ceil
            weights = [min_hamming_weight, max_hamming_weight]*num_pairs
            self.secure_shuffle(weights)
            if weights.length > num_numbers
                weights = weights[0..num_numbers - 1]
            end
        end
        weights.map{|weight| self.generate_constrained_number(weight, bits_per_number - weight)}
    end

    # Returns a max-length cycle over the elements of a.
    # The cycle is a Hash of the form: {some_element => next_element_in_cycle}.
    def self.generate_cycle_map(a)
        cycle = a.clone
        RngTools.secure_shuffle(cycle)
        cycle.push(cycle[0])
        cycle.each_cons(2).to_h
    end
end
