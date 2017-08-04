require 'strscan'

# An interpreter for a very limited subset of ZZT-OOP.
# Supported commands:
# - #give counter amount
# - #take counter amount else_command
# - #labelname (jump to :labelname)
class Program
    class Instruction
        attr_accessor :verb
        attr_accessor :amount
        attr_accessor :counter
        attr_accessor :label
        attr_accessor :next_instruction
        attr_accessor :else_instruction
    end

    def initialize(code)
        @start_instruction, @labeled_instructions = Parser.parse code
    end

    def Program.run(code, counters = {})
        Program.new(code).run(counters)
    end

    def run(counters = {})
        default_counters = {
            'ammo' => 0,
            'gems' => 0,
            'health' => 0,
            'score' => 0,
            'torches' => 0
        }
        counters = default_counters.merge(counters)

        current_instruction = @start_instruction
        until current_instruction == nil
            case current_instruction.verb
            when :give
                sum = counters[current_instruction.counter] + current_instruction.amount
                counters[current_instruction.counter] = sum if sum < 2**15
                current_instruction = current_instruction.next_instruction
            when :take
                difference = counters[current_instruction.counter] - current_instruction.amount
                if difference >= 0
                    counters[current_instruction.counter] = difference
                    current_instruction = current_instruction.next_instruction
                else
                    current_instruction = current_instruction.else_instruction
                end
            when :send
                label = current_instruction.label
                raise "Couldn't find label #{label.inspect}" unless @labeled_instructions.key? label
                current_instruction = @labeled_instructions[label]
            else
                raise "Unrecognized instruction type #{current_instruction.verb.inspect}"
            end
        end
        counters
    end
end

class Parser
    def self.parse(code)
        Parser.new.parse code
    end

    def parse(code)
        instructions = []
        labeled_instructions = {}
        labels_without_instructions = []

        # Parse program into a list of Instruction objects
        tokenize(code)
        until @tokens.empty?
            token = @tokens.shift
            if token == :newline
                # Ignore any extra newlines
            elsif token == :label
                label = parse_word
                raise "Duplicate label #{label}" if labeled_instructions.key?(label)
                labeled_instructions[label] = nil
                labels_without_instructions << label
                parse_end_of_line
            elsif token == :command
                command = parse_command
                instructions << command
                labels_without_instructions.each {|label| labels[label] = command}
                labels_without_instructions = []
                parse_end_of_line
            else
                raise "Unexpected token #{token.inspect}"
            end
        end

        # Link the Instruction objects together
        instructions.each_cons(2) do |this_line, next_line|
            this_instruction = this_line
            loop do
                # For each instruction on the current line, set next_instruction to the start of the next line.
                this_instruction.next_instruction = next_line
                if this_instruction.else_instruction == nil
                    # End of current line.
                    # Make sure conditional commands (i.e., #take) have an else_instruction set.
                    this_instruction.else_instruction = next_line if this_instruction.verb == :take
                    break
                else
                    # The current line continues -- advance the this_instruction pointer
                    this_instruction = this_instruction.else_instruction
                end
            end
        end

        # Return the start instruction and label=>instruction mapping
        [instructions[0], labeled_instructions]
    end

    private

    def parse_token
        raise "Unexpected end-of-input" if @tokens.empty?
        @tokens.shift
    end

    def parse_end_of_line
        token = @tokens.shift || :newline
        raise "Unexpected token #{@tokens[0].inspect}, expected end-of-line" unless token == :newline
        token
    end

    def parse_word
        token = parse_token
        raise "Unexpected token #{token.inspect}, expected a string" unless token.is_a? String
        token
    end

    def parse_counter
        counter = parse_word
        raise "Invalid counter name #{counter.inspect}" unless counter =~ /^(ammo|gems|health|score|torches)$/
        counter
    end

    def parse_int
        int_string = parse_word
        raise "Invalid integer #{int_string.inspect}" unless int_string =~ /^\d+$/
        int = int_string.to_i
        raise "Integer #{int} is outside the range [0, 32767]" unless int >= 0 && int <= 32767
        int
    end

    def parse_command
        instruction = Program::Instruction.new
        first_word = parse_word
        if first_word == 'give'
            instruction.verb = :give
            instruction.counter = parse_counter
            instruction.amount = parse_int
        elsif first_word == 'take'
            instruction.verb = :take
            instruction.counter = parse_counter
            instruction.amount = parse_int
            unless @tokens.empty? || @tokens[0] == :newline
                @tokens.shift if @tokens[0] == :command
                instruction.else_instruction = parse_command
            end
        else
            instruction.verb = :send
            instruction.label = first_word
        end
        instruction
    end

    def tokenize(code)
        @tokens = []
        scanner = StringScanner.new code
        until scanner.eos?
            if scanner.scan(/[#:][\w ]+/)
                mode_tokens = {'#' => :command, ':' => :label}
                @tokens << mode_tokens[scanner.matched[0]]
                @tokens += scanner.matched.scan(/\w+/)
            elsif scanner.scan(/\n/)
                # Newlines are needed for distinguishing "#take foo 1 #take bar 2" vs. "#take foo 1\n#take bar 2"
                @tokens << :newline
            elsif scanner.scan(/[^#:].*\n/)
                # Silently ignore ZZT-OOP messages
            else
                raise "Unexpected #{scanner.match(/\s+|\S+/).inspect} at position #{scanner.pos}"
            end
        end
    end
end
