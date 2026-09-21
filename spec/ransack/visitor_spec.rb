require 'spec_helper'

module Ransack
  describe Visitor do

    let(:viz) { Visitor.new }

    shared_examples 'an or combinator' do | combinator |
      it 'routes to #visit_or' do
        expect(viz).to     receive(:visit_or)
        expect(viz).to_not receive(:visit_and)

        grouping = Ransack::Nodes::Grouping.new(nil, combinator)
        viz.visit_Ransack_Nodes_Grouping(grouping)
      end
    end

    shared_examples 'not an or combinator' do | combinator |
      it 'routes to #visit_or' do
        expect(viz).to_not receive(:visit_or)
        expect(viz).to     receive(:visit_and)

        grouping = Ransack::Nodes::Grouping.new(nil, combinator)
        viz.visit_Ransack_Nodes_Grouping(grouping)
      end
    end

    context 'combinator "or"'  do include_examples 'an or combinator', 'or' end
    context 'combinator "OR"'  do include_examples 'an or combinator', 'OR' end
    context 'combinator ":or"' do include_examples 'an or combinator', :or  end

    context 'combinator "and"'     do include_examples 'not an or combinator', 'and'     end
    context 'combinator "AND"'     do include_examples 'not an or combinator', 'AND'     end
    context 'combinator ":and"'    do include_examples 'not an or combinator', :and      end
    context 'combinator "unknown"' do include_examples 'not an or combinator', 'unknown' end
  end
end
