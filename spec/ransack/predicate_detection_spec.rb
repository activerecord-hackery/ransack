require 'spec_helper'

module Ransack
  # Predicate.detect_from_string looks only at the tail of a key a predicate
  # name can fill. It has to pick what the scan it replaced picked: the
  # longest registered name the key ends with, as `_<name>`.
  describe 'Predicate.detect_from_string' do
    def longest_first(str)
      Ransack.predicates.sorted_names_with_underscores.each do |predicate, underscored|
        return predicate if str.end_with?(underscored)
      end
      nil
    end

    names = Ransack.predicates.keys
    keys = names.flat_map { |name| ["title_#{name}", "a_b_c_#{name}", "_#{name}", name] }
    keys += %w[
      name_not_eq_all name_eq_all name_in_not_in title_i_cont_any not_eq
      created_at_gteq_any x_ eq_ _ title name_not_null_extra
    ]
    keys += ['', "#{'a_' * 300}eq", "#{'a_' * 300}"]
    random = Random.new(1757)
    keys += Array.new(500) do
      Array.new(random.rand(1..6)) { (names + %w[a b x id]).sample(random: random) }.join('_')
    end

    it 'finds the same predicate as a longest-first scan, for every key' do
      mismatches = keys.uniq.reject do |key|
        Predicate.detect_from_string(key.dup) == longest_first(key)
      end
      expect(mismatches).to be_empty
    end

    it 'strips exactly that predicate when asked to' do
      keys.uniq.each do |key|
        str = key.dup
        predicate = Predicate.detect_and_strip_from_string!(str)
        expected = predicate ? key.delete_suffix("_#{predicate}") : key
        expect(str).to eq(expected), "stripping #{key.inspect}"
      end
    end

    it 'accepts a symbol when not stripping' do
      expect(Predicate.detect_from_string(:name_cont)).to eq 'cont'
    end

    it 'sees a predicate registered after the others, however long its name' do
      long_name = 'matches_a_really_long_custom_predicate_name'
      Ransack.configure { |c| c.add_predicate long_name, arel_predicate: 'matches' }
      expect(Predicate.detect_from_string("title_#{long_name}")).to eq long_name
    end
  end
end
