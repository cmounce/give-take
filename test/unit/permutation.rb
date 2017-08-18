require 'interpreter'
require 'permutation'
require 'test/unit'

class TestPermutation < Test::Unit::TestCase
    def test_wrapping_add_zero
        c = Program::run(generate_wrapping_add_code('gems', 0))
        assert_equal 0, c['gems']
    end

    def test_wrapping_add_nowrap
        c = Program::run(generate_wrapping_add_code('gems', 100))
        assert_equal 100, c['gems']
        c = Program::run(generate_wrapping_add_code('gems', 200), c)
        assert_equal 300, c['gems']
    end

    def test_wrapping_add_wrap
        c = Program::run(generate_wrapping_add_code('gems', 32000), {'gems' => 10000})
        assert_equal (32000 + 10000) % (2**15), c['gems']
    end
end
