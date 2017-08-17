require 'digest'
require 'securerandom'

# A collection of random-number utility functions.
# All random numbers are securely generated. In this context, "secure" means that past outputs cannot be used
# to predict future outputs, and vice-versa. This is overkill, but hey, this whole project is overkill.
class RngTools
    def initialize(seed = nil)
        @seed = seed || SecureRandom.random_bytes(16)
        @counter = 0
    end

    # Returns a random integer from 0 to n-1, inclusive.
    # Assumes that n is relatively small (i.e., not a Bignum).
    def random_number(n)
        # Generate a large random number, using an algorithm based on MGF1.
        hash = Digest::SHA256.digest([@counter].pack('Q<') + @seed)
        @counter += 1
        r = hash.bytes.reduce(0){|acc, b| (acc << 8) + b}

        # Calculating r modulo n is not strictly correct. But r's range is so
        # ridiculously big that the chances of this introducing bias are negligible.
        r%n
    end

    # Shuffles the given array
    def secure_shuffle(a)
        (0..a.length - 1).each do |i|
            j = i + random_number(a.length - i)
            a[i], a[j] = a[j], a[i]
        end
    end

    # Returns a random int that, in binary, has the specified counts of 1s and 0s.
    def generate_constrained_number(num_ones, num_zeros)
        bits = [1]*num_ones + [0]*num_zeros
        self.secure_shuffle(bits)
        bits.reduce(0){|acc, bit| acc*2 + bit}
    end

    # Returns an array of random ints, each one bits_per_number long.
    # Each int will have half of its bits set to 1 and half set to 0.
    # If bits_per_number is odd, this function will generate ints that
    # are as close as possible to having an equal number of 1s and 0s.
    def generate_balanced_numbers(num_numbers, bits_per_number)
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
    def generate_cycle_map(a)
        cycle = a.clone
        secure_shuffle(cycle)
        cycle.push(cycle[0])
        cycle.each_cons(2).to_h
    end
end
