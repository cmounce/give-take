require 'interpreter'
require 'permutation'
require 'set'
require 'test/unit'

# TODO: https://eprint.iacr.org/2010/564.pdf

class TestPermutation < Test::Unit::TestCase
    def test_permutation_has_no_birthday_paradox
        code = Permutation.new(4).generate_code
        program = Program.new(code)
        results = Set.new

        # If we feed in all 2**30 possible inputs, each output should appear only once.
        # This means that if we use the permutation to generate a bunch of pseudorandom
        # numbers, the birthday paradox should not apply to the numbers we generate.
        probability_of_collision = 0.9
        # https://en.wikipedia.org/wiki/Birthday_problem#Reverse_problem
        n = Math.sqrt(2*(2**30)*Math.log(1/(1 - probability_of_collision))).round
        n.times do |i|
            counters = {'ammo' => (i >> 15), 'gems' => (i & 0x7FFF)}
            counters = program.run(counters)
            result = (counters['ammo'] << 15) + counters['gems']
            assert !results.include?(result)
            results << result
        end
    end
end
