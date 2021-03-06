require 'rngtools'
require 'set'
require 'test/unit'

class TestRngTools < Test::Unit::TestCase
    def setup
        @rng_tools = RngTools.new
    end

    def test_sample
        def sample(n)
            @rng_tools.sample (0..9).to_a, n
        end
        [0, 1, 9, 10].each do |n|
            s = sample(n)
            assert_equal n, s.length
            assert_equal n, s.uniq.length
            assert s.all?{|e| (0..9).cover?(e) }
        end
    end

    def test_shuffle
        a = (0..9).to_a
        a = @rng_tools.shuffle(a)
        assert_equal(10, a.length)
        (0..9).each do |x|
            assert_equal(1, a.count{|y| x == y})
        end
    end

    def test_binary_matrix_shuffle
        unshuffleable_matrixes = [
            [],
            [[0]],
            [[0, 1, 0]],
            [[1], [0], [1]],
            [[1, 1], [1, 1]]
        ]
        unshuffleable_matrixes.each do |m|
            assert_equal m, @rng_tools.binary_matrix_shuffle(m)
        end

        # Shuffle a checkerboard
        checkerboard = 8.times.map{|i| 8.times.map{|j| (i ^ j) & 1}}
        shuffled = @rng_tools.binary_matrix_shuffle(checkerboard)
        assert_equal [4]*8, shuffled.map{|row| row.count(1)}
        assert_equal [4]*8, 8.times.map{|col| 8.times.map{|row| shuffled[row][col]}.count(1)}
    end

    def test_generate_constrained_number
        def test(num_ones, num_zeros)
            n = @rng_tools.generate_constrained_number(num_ones, num_zeros)
            binary_digits = n.to_s(2).rjust(num_ones + num_zeros, '0').chars
            assert_equal(num_ones + num_zeros, binary_digits.length)
            assert_equal(num_ones, binary_digits.count{|c| c == '1'})
            assert_equal(num_zeros, binary_digits.count{|c| c == '0'})
        end
        assert_equal(0, @rng_tools.generate_constrained_number(0, 0))
        test(0, 1)
        test(0, 5)
        test(1, 0)
        test(5, 0)
        100.times{test(10, 10)}
    end

    def test_generate_balanced_numbers
        def assert_close(expected, actual)
            if expected.round == expected
                assert_equal(expected, actual)
            else
                assert((expected.ceil == actual) || (expected.floor == actual))
            end
        end
        def test(num_numbers, bits_per_number)
            ints = @rng_tools.generate_balanced_numbers(num_numbers, bits_per_number)
            assert_equal(num_numbers, ints.length)

            expected_hamming_weight = bits_per_number/2.0
            actual_hamming_weights = ints.map{|i| i.to_s(2).chars.count{|c| c == '1'}}
            actual_hamming_weights.each{|w| assert_close(expected_hamming_weight, w)}

            expected_total_hamming_weight = expected_hamming_weight*num_numbers
            actual_total_hamming_weight = actual_hamming_weights.reduce(0, :+)
            assert_close(expected_total_hamming_weight, actual_total_hamming_weight)
        end
        test(0, 0)
        test(0, 1)
        test(1, 0)
        test(1, 1)
        test(4, 4)
        test(4, 5)
        test(5, 4)
        test(5, 5)
    end

    def test_generate_cycle_map
        [0, 1, 2, 10].each do |n|
            array = (1..n).to_a
            cycle_map = @rng_tools.generate_cycle_map(array)
            assert_equal(array.length, cycle_map.length)
            assert_equal(array.to_set, cycle_map.keys.to_set)
            assert_equal(array.to_set, cycle_map.values.to_set)

            element = array[0]
            array.length.times do
                next_element = cycle_map[element]
                assert(next_element != element) unless array.length == 1
                element = next_element
            end
            assert_equal(array[0], element)
        end
    end
end
