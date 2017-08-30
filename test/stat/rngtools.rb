require 'rngtools'
require 'test/unit'

class TestRngTools < Test::Unit::TestCase
    def setup
        @rng_tools = RngTools.new
    end

    def test_shuffle_fairness
        # TODO: Another test for sample()?
        counts = {}
        num_samples = 10000
        num_samples.times do
            a = ['a', 'b', 'c', 'd']
            a = @rng_tools.shuffle(a)
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
end
