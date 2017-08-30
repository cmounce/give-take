require 'digest'
require 'securerandom'
require 'set'

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
        raise "n must be positive" unless n > 0
        return 0 if n == 1

        # Generate a large random number, using an algorithm based on MGF1.
        hash = Digest::SHA256.digest([@counter].pack('Q<') + @seed)
        @counter += 1
        r = hash.bytes.reduce(0){|acc, b| (acc << 8) + b}

        # Calculating r modulo n is not strictly correct. But r's range is so
        # ridiculously big that the chances of this introducing bias are negligible.
        r%n
    end

    # Returns an array of values sampled from array (without replacement)
    def sample(array, num_samples)
        raise "num_samples must be in the range [0, array.length]" unless (0..array.length).cover? num_samples
        array = array.clone
        (0..(num_samples - 1)).each do |i|
            j = i + random_number(array.length - i)
            array[i], array[j] = array[j], array[i]
        end
        array.slice(0, num_samples)
    end

    # Returns a shuffled copy of the given array
    def shuffle(a)
        sample(a, a.length)
    end

    # Shuffles a binary matrix using the Babe Ruth algorithm: https://arxiv.org/abs/1404.3466v1
    # This is a constrained shuffle: the row/column sums of the input matrix will match those of the output matrix.
    def binary_matrix_shuffle(m)
        m = m.map do |row|
            raise "Matrix elements may only be 0 or 1" unless row.all?{|e| (0..1).cover? e}
            row.clone
        end
        width = (m[0] || []).length
        height = m.length
        return m if width <= 1 || height <= 1 # Matrix must have multiple rows and multiple columns
        return matrix_shuffle(m.transpose).transpose if height > width # If matrix is tall, make it wide instead

        # Convert each row of the matrix into a set
        row_sets = m.map do |row|
            indexes = row.each_with_index.map{|bit, i| i if bit == 1}.compact
            Set.new indexes
        end

        # Run the Babe Ruth algorithm
        num_trades = 10*width # arXiv:1404.3466v1 says average requirement is 1.2*width. I'm being conservative.
        num_trades.times do
            # Pick two rows
            x, y = sample(row_sets, 2)

            # Figure out which cards each row can trade
            x_can_give = x - y
            y_can_give = y - x
            trade_max_size = [x_can_give.length, y_can_give.length].min
            next if trade_max_size == 0

            # Figure out how many to trade. At least 1, at most trade_max_size
            trade_size = 1 + random_number(trade_max_size)

            # Figure out which cards to trade
            x_gives = sample(x_can_give.to_a.sort, trade_size)
            y_gives = sample(y_can_give.to_a.sort, trade_size)

            # Actually trade
            x.subtract(x_gives).merge(y_gives)
            y.subtract(y_gives).merge(x_gives)
        end

        # Convert sets back to a matrix
        height.times do |y|
            row = m[y]
            row_set = row_sets[y]
            width.times do |x|
                row[x] = if row_set.include?(x) then 1 else 0 end
            end
        end
        m
    end

    # Returns a random int that, in binary, has the specified counts of 1s and 0s.
    def generate_constrained_number(num_ones, num_zeros)
        bits = [1]*num_ones + [0]*num_zeros
        bits = shuffle(bits)
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
            weights = shuffle(weights)
            if weights.length > num_numbers
                weights = weights[0..num_numbers - 1]
            end
        end
        weights.map{|weight| self.generate_constrained_number(weight, bits_per_number - weight)}
    end

    # Returns a max-length cycle over the elements of a.
    # The cycle is a Hash of the form: {some_element => next_element_in_cycle}.
    def generate_cycle_map(a)
        cycle = shuffle(a)
        cycle.push(cycle[0])
        cycle.each_cons(2).to_h
    end
end
