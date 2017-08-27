require 'interpreter'
require 'test/unit'

class TestInterpreter < Test::Unit::TestCase
    def run_program(code, counters = {})
        code = code.lines.map(&:lstrip).reject(&:empty?).join
        Program::run(code, counters)
    end

    def test_empty
        run_program ''
    end

    def test_goto_label
        c = run_program '
            #a
            #give gems 1
            :a
        '
        assert_equal 0, c[:gems]
    end

    def test_goto_label_in_middle_of_program
        c = run_program '
            #a
            #give gems 1
            :a
            #give gems 2
        '
        assert_equal 2, c[:gems]
    end

    def test_give
        c = run_program '#give health 100'
        assert_equal 100, c[:health]
    end

    def test_give_overflow
        c = run_program "#give ammo #{32767-100+1}", {:ammo => 100}
        assert_equal 100, c[:ammo]
        c = run_program "#give ammo #{32767-100}", c
        assert_equal 32767, c[:ammo]
    end

    def test_take
        c = run_program '#take score 10', {:score => 20}
        assert_equal 10, c[:score]
    end

    def test_take_underflow
        c = run_program '#take torches 10', {:torches => 5}
        assert_equal 5, c[:torches]
        c = run_program '#take torches 5', c
        assert_equal 0, c[:torches]
    end

    def test_take_else
        c = run_program '
            #take gems 10 toopoor
            #give ammo 20
            :toopoor
        '
        assert_equal 0, c[:ammo]
    end

    def test_take_longline
        c = run_program '#take gems 10 take ammo 10 give ammo 90'
        assert_equal 90, c[:ammo]
    end

    def test_multirun
        p = Program.new '#give gems 1'
        c = p.run
        c = p.run c
        assert_equal 2, c[:gems]
    end
end
