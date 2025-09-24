# frozen_string_literal: true

require "rubygems"
require "pathname"

require "psych" if RUBY_VERSION >= "1.9"

if ENV["COVERAGE"]
  require "simplecov"
  require "simplecov-lcov"

  SimpleCov::Formatter::LcovFormatter.config do |config|
    config.report_with_single_file = true
    config.lcov_file_name = "lcov.info"
  end

  SimpleCov.start "test_frameworks" do
    enable_coverage :branch
    primary_coverage :branch
    formatter SimpleCov::Formatter::MultiFormatter.new([
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::LcovFormatter,
      SimpleCov::Formatter::SimpleFormatter
    ])
  end
end

file = Pathname.new(__FILE__).expand_path
path = file.parent
parent = path.parent

$:.unshift parent.join("lib")

module CaptureSubprocessIO
  def _synchronize
    yield
  end

  def capture_subprocess_io
    _synchronize { _capture_subprocess_io { yield } }
  end

  def _capture_subprocess_io
    require "tempfile"

    captured_stdout, captured_stderr = Tempfile.new("out"), Tempfile.new("err")

    orig_stdout, orig_stderr = $stdout.dup, $stderr.dup
    $stdout.reopen captured_stdout
    $stderr.reopen captured_stderr

    yield

    $stdout.rewind
    $stderr.rewind

    [captured_stdout.read, captured_stderr.read]
  ensure
    captured_stdout.unlink
    captured_stderr.unlink
    $stdout.reopen orig_stdout
    $stderr.reopen orig_stderr
  end
  private :_capture_subprocess_io
end

require "diff-lcs"

module Diff::LCS::SpecHelper
  def hello
    "hello"
  end

  def hello_ary
    %w[h e l l o]
  end

  def seq1
    %w[a b c e h j l m n p]
  end

  def skipped_seq1
    %w[a h n p]
  end

  def seq2
    %w[b c d e f j k l m r s t]
  end

  def skipped_seq2
    %w[d f k r s t]
  end

  def word_sequence
    %w[abcd efgh ijkl mnopqrstuvwxyz]
  end

  def correct_lcs
    %w[b c e j l m]
  end

  # standard:disable Layout/ExtraSpacing
  def correct_forward_diff
    [
      [
        ["-",  0, "a"]
      ],
      [
        ["+",  2, "d"]
      ],
      [
        ["-",  4, "h"],
        ["+",  4, "f"]
      ],
      [
        ["+",  6, "k"]
      ],
      [
        ["-",  8, "n"],
        ["+",  9, "r"],
        ["-",  9, "p"],
        ["+", 10, "s"],
        ["+", 11, "t"]
      ]
    ]
  end

  def correct_backward_diff
    [
      [
        ["+",  0, "a"]
      ],
      [
        ["-",  2, "d"]
      ],
      [
        ["-",  4, "f"],
        ["+",  4, "h"]
      ],
      [
        ["-",  6, "k"]
      ],
      [
        ["-",  9, "r"],
        ["+",  8, "n"],
        ["-", 10, "s"],
        ["+",  9, "p"],
        ["-", 11, "t"]
      ]
    ]
  end

  def correct_forward_sdiff
    [
      ["-", [0, "a"], [0, nil]],
      ["=", [1, "b"], [0, "b"]],
      ["=", [2, "c"], [1, "c"]],
      ["+", [3, nil], [2, "d"]],
      ["=", [3, "e"], [3, "e"]],
      ["!", [4, "h"], [4, "f"]],
      ["=", [5, "j"], [5, "j"]],
      ["+", [6, nil], [6, "k"]],
      ["=", [6, "l"], [7, "l"]],
      ["=", [7, "m"], [8, "m"]],
      ["!", [8, "n"], [9, "r"]],
      ["!", [9, "p"], [10, "s"]],
      ["+", [10, nil], [11, "t"]]
    ]
  end
  # standard:enable Layout/ExtraSpacing

  def reverse_sdiff(forward_sdiff)
    forward_sdiff.map { |line|
      line[1], line[2] = line[2], line[1]
      case line[0]
      when "-" then line[0] = "+"
      when "+" then line[0] = "-"
      end
      line
    }
  end

  def change_diff(diff)
    map_diffs(diff, Diff::LCS::Change)
  end

  def context_diff(diff)
    map_diffs(diff, Diff::LCS::ContextChange)
  end

  def format_diffs(diffs)
    diffs.map { |e|
      if e.is_a?(Array)
        e.map { |f| f.to_a.join }.join(", ")
      else
        e.to_a.join
      end
    }.join("\n")
  end

  def map_diffs(diffs, klass = Diff::LCS::ContextChange)
    diffs.map do |chunks|
      if klass == Diff::LCS::ContextChange
        klass.from_a(chunks)
      else
        chunks.map { |changes| klass.from_a(changes) }
      end
    end
  end

  def balanced_traversal(s1, s2, callback_type)
    callback = __send__(callback_type)
    Diff::LCS.traverse_balanced(s1, s2, callback)
    callback
  end

  def balanced_reverse(change_result)
    new_result = []
    change_result.each do |line|
      line = [line[0], line[2], line[1]]
      case line[0]
      when "<"
        line[0] = ">"
      when ">"
        line[0] = "<"
      end
      new_result << line
    end
    new_result.sort_by { |line| [line[1], line[2]] }
  end

  def map_to_no_change(change_result)
    new_result = []
    change_result.each do |line|
      case line[0]
      when "!"
        new_result << ["<", line[1], line[2]]
        new_result << [">", line[1] + 1, line[2]]
      else
        new_result << line
      end
    end
    new_result
  end

  class SimpleCallback
    def initialize
      reset
    end

    attr_reader :matched_a
    attr_reader :matched_b
    attr_reader :discards_a
    attr_reader :discards_b
    attr_reader :done_a
    attr_reader :done_b

    def reset
      @matched_a = []
      @matched_b = []
      @discards_a = []
      @discards_b = []
      @done_a = []
      @done_b = []
      self
    end

    def match(event)
      @matched_a << event.old_element
      @matched_b << event.new_element
    end

    def discard_b(event)
      @discards_b << event.new_element
    end

    def discard_a(event)
      @discards_a << event.old_element
    end

    def finished_a(event)
      @done_a << [
        event.old_element, event.old_position,
        event.new_element, event.new_position
      ]
    end

    def finished_b(event)
      @done_b << [
        event.old_element, event.old_position,
        event.new_element, event.new_position
      ]
    end
  end

  def simple_callback
    SimpleCallback.new
  end

  class SimpleCallbackNoFinishers < SimpleCallback
    undef :finished_a
    undef :finished_b
  end

  def simple_callback_no_finishers
    SimpleCallbackNoFinishers.new
  end

  class BalancedCallback
    def initialize
      reset
    end

    attr_reader :result

    def reset
      @result = []
    end

    def match(event)
      @result << ["=", event.old_position, event.new_position]
    end

    def discard_a(event)
      @result << ["<", event.old_position, event.new_position]
    end

    def discard_b(event)
      @result << [">", event.old_position, event.new_position]
    end

    def change(event)
      @result << ["!", event.old_position, event.new_position]
    end
  end

  def balanced_callback
    BalancedCallback.new
  end

  class BalancedCallbackNoChange < BalancedCallback
    undef :change
  end

  def balanced_callback_no_change
    BalancedCallbackNoChange.new
  end

  module Matchers
    extend RSpec::Matchers::DSL

    matcher :be_nil_or_match_values do |ii, s1, s2|
      match do |ee|
        expect(ee).to(satisfy { |vee| vee.nil? || s1[ii] == s2[ee] })
      end
    end

    matcher :correctly_map_sequence do |s1|
      match do |actual|
        actual.each_index { |ii| expect(actual[ii]).to be_nil_or_match_values(ii, s1, @s2) }
      end

      chain :to_other_sequence do |s2|
        @s2 = s2
      end
    end
  end
end

RSpec.configure do |conf|
  conf.include Diff::LCS::SpecHelper
  conf.alias_it_should_behave_like_to :it_has_behavior, "has behavior:"
  # standard:disable Style/HashSyntax
  conf.filter_run_excluding :broken => true
  # standard:enable Style/HashSyntax
end
