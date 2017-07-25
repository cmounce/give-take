#!/usr/bin/env ruby
require_relative 'rngtools'
require 'test/unit'

class TestRngTools < Test::Unit::TestCase
    def test_secure_shuffle
        a = (0..9).to_a
        RngTools.secure_shuffle(a)
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
            RngTools.secure_shuffle(a)
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
            n = RngTools.generate_constrained_number(num_ones, num_zeros)
            binary_digits = n.to_s(2).rjust(num_ones + num_zeros, '0').chars
            assert_equal(num_ones + num_zeros, binary_digits.length)
            assert_equal(num_ones, binary_digits.count{|c| c == '1'})
            assert_equal(num_zeros, binary_digits.count{|c| c == '0'})
        end
        assert_equal(0, RngTools.generate_constrained_number(0, 0))
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
            ints = RngTools.generate_balanced_numbers(num_numbers, bits_per_number)
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
end
