require 'rngtools'
require 'set'
require 'test/unit'

class TestRngTools < Test::Unit::TestCase
    def setup
        @rng_tools = RngTools.new
    end

    def test_secure_shuffle
        a = (0..9).to_a
        @rng_tools.secure_shuffle(a)
        assert_equal(10, a.length)
        (0..9).each do |x|
            assert_equal(1, a.count{|y| x == y})
        end
    end

    def test_secure_shuffle_fairness
        counts = {}
        num_samples = 10000
        num_samples.times do
            a = ['a', 'b', 'c', 'd']
            @rng_tools.secure_shuffle(a)
            key = a.join ''
            unless counts.key? key
                counts[key] = 0
            end
            counts[key] += 1
        end

        num_permutations = 4*3*2*1
        assert_equal(num_permutations, counts.length)

        permutation_probability = 1.0/num_permutations
        expected_count = num_samples*permutation_probability
        expected_variance = num_samples*permutation_probability*(1.0 - permutation_probability)
        expected_std_dev = expected_variance**0.5
        counts.values.each do |actual_count|
            z_score = (actual_count - expected_count)/expected_std_dev
            assert(z_score.abs < 3.72) # Corresponds to p = 0.0001
        end
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
