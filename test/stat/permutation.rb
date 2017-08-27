require 'interpreter'
require 'permutation'
require 'set'
require 'test/unit'

# TODO: Implement more of the tests suggested in https://eprint.iacr.org/2010/564.pdf

class TestPermutation < Test::Unit::TestCase
    def setup
        @seed = Random.rand(2**64).to_s
        code = Permutation.new(5, @seed).generate_code
        @program = Program.new(code)
    end

    def permute(n)
        counters = {:ammo => (n >> 15), :gems => (n & 0x7FFF)}
        counters = @program.run(counters)
        (counters[:ammo] << 15) | counters[:gems]
    end

    def test_no_birthday_paradox
        # If we feed in all 2**30 possible inputs, each output should appear exactly once.
        # This means that if we use the permutation to generate a bunch of pseudorandom
        # numbers, the birthday paradox should not apply to the numbers we generate.
        probability_of_collision = 0.9
        outputs = Set.new
        # Formula from https://en.wikipedia.org/wiki/Birthday_problem#Reverse_problem
        n = Math.sqrt(2*(2**30)*Math.log(1/(1 - probability_of_collision))).round
        n.times do |i|
            output = permute(i)
            assert !outputs.include?(output), "Collision found with seed #{@seed}"
            outputs << output
        end
    end

    def test_strict_avalanche_criterion
        # The SAC says that if we flip a single input bit, then each output bit will have a 50% chance of flipping.
        # To test this, we'll flip single bits on various input values, and count how many output bits flip.
        num_trials = 1000
        def run_sac_test(num_trials)
            # bit_flip_counts[i][j] = how many times flipping i-th input bit caused j-th output bit to flip
            bit_flip_counts = 30.times.map{[0]*30}
            num_trials.times do # Choose a random input value
                input = Random.rand 2**30
                output = permute(input)
                30.times do |i| # Flip each input bit, one at a time
                    new_input = input ^ (1 << i)
                    new_output = permute(new_input)
                    flipped_output_bits = output ^ new_output
                    30.times do |j| # Record which output bits flipped
                        bit_flip_counts[i][j] += 1 unless (flipped_output_bits & (1 << j)) == 0
                    end
                end
            end
            bit_flip_counts
        end

        # Calculate expected distribution parameters
        flip_probability = 0.5 # Probability that flipping the i-th input bit will flip the j-th output bit
        expected_count = num_trials*flip_probability # Each trial touches each entry in bit_flip_counts exactly once
        expected_variance = expected_count*flip_probability*(1.0 - flip_probability)
        expected_std_dev = Math.sqrt(expected_variance)

        # Generate some bit-flip count matrixes, and check them for biases
        is_count_biased = proc do |count|
            z_score = (count - expected_count)/expected_std_dev
            z_score.abs > 3.72 # Corresponds to p = 0.0001
        end
        counts1 = run_sac_test(num_trials)
        counts2 = run_sac_test(num_trials)
        30.times do |i|
            30.times do |j|
                # We have 900 entries, so we may have some false positives.
                # To mitigate false positives, we only fail if we detect bias in a given (i, j) pair twice
                if is_count_biased[counts1[i][j]]
                    assert !is_count_biased[counts2[i][j]], "Input bit #{i} correlated with output bit #{j}, seed #{@seed}"
                end
            end
        end

        # TODO: Verify that bit_flip_counts follows a normal distribution?
        # For doing something like Kolmogorov–Smirnov, we need a CDF for the normal curve
    end
end
