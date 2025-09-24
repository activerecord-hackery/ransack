# frozen_string_literal: true

class Pry
  class REPL
    extend Pry::Forwardable
    def_delegators :@pry, :input, :output

    # @return [Pry] The instance of {Pry} that the user is controlling.
    attr_accessor :pry

    # Instantiate a new {Pry} instance with the given options, then start a
    # {REPL} instance wrapping it.
    # @option options See {Pry#initialize}
    def self.start(options)
      new(Pry.new(options)).start
    end

    # Create an instance of {REPL} wrapping the given {Pry}.
    # @param [Pry] pry The instance of {Pry} that this {REPL} will control.
    # @param [Hash] options Options for this {REPL} instance.
    # @option options [Object] :target The initial target of the session.
    def initialize(pry, options = {})
      @pry    = pry
      @indent = Pry::Indent.new(pry)

      @readline_output = nil

      @pry.push_binding options[:target] if options[:target]
    end

    # Start the read-eval-print loop.
    # @return [Object?] If the session throws `:breakout`, return the value
    #   thrown with it.
    # @raise [Exception] If the session throws `:raise_up`, raise the exception
    #   thrown with it.
    def start
      prologue
      Pry::InputLock.for(:all).with_ownership { repl }
    ensure
      epilogue
    end

    private

    # Set up the repl session.
    # @return [void]
    def prologue
      pry.exec_hook :before_session, pry.output, pry.current_binding, pry

      return unless pry.config.correct_indent

      # Clear the line before starting Pry. This fixes issue #566.
      output.print(Helpers::Platform.windows_ansi? ? "\e[0F" : "\e[0G")
    end

    # The actual read-eval-print loop.
    #
    # The {REPL} instance is responsible for reading and looping, whereas the
    # {Pry} instance is responsible for evaluating user input and printing
    # return values and command output.
    #
    # @return [Object?] If the session throws `:breakout`, return the value
    #   thrown with it.
    # @raise [Exception] If the session throws `:raise_up`, raise the exception
    #   thrown with it.
    def repl
      loop do
        case val = read
        when :control_c
          output.puts ""
          pry.reset_eval_string
        when :no_more_input
          output.puts "" if output.tty?
          break
        else
          output.puts "" if val.nil? && output.tty?
          return pry.exit_value unless pry.eval(val)
        end
      end
    end

    # Clean up after the repl session.
    # @return [void]
    def epilogue
      pry.exec_hook :after_session, pry.output, pry.current_binding, pry
    end

    # Read a line of input from the user.
    # @return [String] The line entered by the user.
    # @return [nil] On `<Ctrl-D>`.
    # @return [:control_c] On `<Ctrl+C>`.
    # @return [:no_more_input] On EOF.
    def read
      @indent.reset if pry.eval_string.empty?
      current_prompt = pry.select_prompt
      indentation = pry.config.auto_indent ? @indent.current_prefix : ''

      val = read_line("#{current_prompt}#{indentation}")

      # Return nil for EOF, :no_more_input for error, or :control_c for <Ctrl-C>
      return val unless val.is_a?(String)

      if pry.config.auto_indent && !input_multiline?
        original_val = "#{indentation}#{val}"
        indented_val = @indent.indent(val)

        if output.tty? &&
           pry.config.correct_indent &&
           Pry::Helpers::BaseHelpers.use_ansi_codes?
          output.print @indent.correct_indentation(
            current_prompt,
            indented_val,
            calculate_overhang(current_prompt, original_val, indented_val)
          )
          output.flush
        end
      else
        indented_val = val
      end

      indented_val
    end

    # Manage switching of input objects on encountering `EOFError`s.
    # @return [Object] Whatever the given block returns.
    # @return [:no_more_input] Indicates that no more input can be read.
    def handle_read_errors
      should_retry = true
      exception_count = 0

      begin
        yield
      rescue EOFError
        pry.config.input = Pry.config.input
        unless should_retry
          output.puts "Error: Pry ran out of things to read from! " \
            "Attempting to break out of REPL."
          return :no_more_input
        end
        should_retry = false
        retry

      # Handle <Ctrl+C> like Bash: empty the current input buffer, but don't
      # quit.
      rescue Interrupt
        return :control_c

      # If we get a random error when trying to read a line we don't want to
      # automatically retry, as the user will see a lot of error messages
      # scroll past and be unable to do anything about it.
      rescue RescuableException => e
        puts "Error: #{e.message}"
        output.puts e.backtrace
        exception_count += 1
        retry if exception_count < 5
        puts "FATAL: Pry failed to get user input using `#{input}`."
        puts "To fix this you may be able to pass input and output file " \
          "descriptors to pry directly. e.g."
        puts "  Pry.config.input = STDIN"
        puts "  Pry.config.output = STDOUT"
        puts "  binding.pry"
        return :no_more_input
      end
    end

    # Returns the next line of input to be sent to the {Pry} instance.
    # @param [String] current_prompt The prompt to use for input.
    # @return [String?] The next line of input, or `nil` on <Ctrl-D>.
    def read_line(current_prompt)
      handle_read_errors do
        if coolline_available?
          input.completion_proc = proc do |cool|
            completions = @pry.complete cool.completed_word
            completions.compact
          end
        elsif input.respond_to? :completion_proc=
          input.completion_proc = proc do |inp|
            @pry.complete inp
          end
        end

        if reline_available?
          Reline.output_modifier_proc = lambda do |text, _|
            if pry.color
              SyntaxHighlighter.highlight(text)
            else
              text
            end
          end

          if pry.config.auto_indent
            Reline.auto_indent_proc = lambda do |lines, line_index, _byte_ptr, _newline|
              if line_index == 0
                0
              else
                pry_indentation = Pry::Indent.new
                pry_indentation.indent(lines.join("\n"))
                pry_indentation.last_indent_level.length
              end
            end
          end
        end

        if input_multiline?
          input_readmultiline(current_prompt, false)
        elsif readline_available?
          set_readline_output
          input_readline(current_prompt, false) # false since we'll add it manually
        elsif coolline_available?
          input_readline(current_prompt)
        elsif input.method(:readline).arity == 1
          input_readline(current_prompt)
        else
          input_readline
        end
      end
    end

    def input_readmultiline(*args)
      Pry::InputLock.for(:all).interruptible_region do
        input.readmultiline(*args) do |multiline_input|
          Pry.commands.find_command(multiline_input) ||
            (complete_expression?(multiline_input) && !Reline::IOGate.in_pasting?)
        end
      end
    end

    def input_readline(*args)
      Pry::InputLock.for(:all).interruptible_region do
        input.readline(*args)
      end
    end

    def input_multiline?
      !!pry.config.multiline && reline_available?
    end

    def reline_available?
      defined?(Reline) && input == Reline
    end

    def readline_available?
      defined?(Readline) && input == Readline
    end

    def coolline_available?
      defined?(Coolline) && input.is_a?(Coolline)
    end

    def prism_available?
      @prism_available ||= begin
        # rubocop:disable Lint/SuppressedException
        begin
          require 'prism'
        rescue LoadError
        end
        # rubocop:enable Lint/SuppressedException

        defined?(Prism::VERSION) &&
          Gem::Version.new(Prism::VERSION) >= Gem::Version.new('0.25.0')
      end
    end

    # If `$stdout` is not a tty, it's probably a pipe.
    # @example
    #   # `piping?` returns `false`
    #   % pry
    #   [1] pry(main)
    #
    #   # `piping?` returns `true`
    #   % pry | tee log
    def piping?
      return false unless $stdout.respond_to?(:tty?)

      !$stdout.tty? && $stdin.tty? && !Helpers::Platform.windows?
    end

    # @return [void]
    def set_readline_output
      return if @readline_output

      @readline_output = (Readline.output = Pry.config.output) if piping?
    end

    UNEXPECTED_TOKENS = %i[unexpected_token_ignore lambda_open].freeze

    def complete_expression?(multiline_input)
      if prism_available?
        lex = Prism.lex(multiline_input)

        errors = lex.errors
        return true if errors.empty?

        errors.any? { |error| UNEXPECTED_TOKENS.include?(error.type) }
      else
        Pry::Code.complete_expression?(multiline_input)
      end
    end

    # Calculates correct overhang for current line. Supports vi Readline
    # mode and its indicators such as "(ins)" or "(cmd)".
    #
    # @return [Integer]
    # @note This doesn't calculate overhang for Readline's emacs mode with an
    #   indicator because emacs is the default mode and it doesn't use
    #   indicators in 99% of cases.
    def calculate_overhang(current_prompt, original_val, indented_val)
      overhang = original_val.length - indented_val.length

      if readline_available? && Readline.respond_to?(:vi_editing_mode?)
        begin
          # rb-readline doesn't support this method:
          # https://github.com/ConnorAtherton/rb-readline/issues/152
          if Readline.vi_editing_mode?
            overhang = output.width - current_prompt.size - indented_val.size
          end
        rescue NotImplementedError
          # VI editing mode is unsupported on JRuby.
          # https://github.com/pry/pry/issues/1840
          nil
        end
      end
      [0, overhang].max
    end
  end
end
