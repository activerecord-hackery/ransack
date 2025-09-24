require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Double join issue with pluck' do
        context 'when using pluck with ransack on already joined query' do
          it 'reproduces the erroneous double-join when using pluck' do
            # Based on the issue description, we need to reproduce this exact scenario:
            # Visitor.includes(:automated_campaign_receipts)
            #   .where(automated_campaign_receipts: { automated_campaign_id: 10 })
            #   .ransack({automated_campaign_receipts_event_type_eq: 'clicked'})
            #   .result.pluck(:id)
            
            # Create test data
            campaign = ::AutomatedCampaign.create!(name: 'Test Campaign')
            visitor = ::Visitor.create!(name: 'Test Visitor')
            ::AutomatedCampaignReceipt.create!(
              visitor: visitor, 
              automated_campaign: campaign, 
              event_type: 'clicked'
            )

            # This is the query that should work correctly (from the issue description)
            correct_query = ::Visitor.includes(:automated_campaign_receipts)
                                     .where(automated_campaign_receipts: { automated_campaign_id: campaign.id })
                                     .where(automated_campaign_receipts: { event_type: 'clicked' })

            # This is the problematic query that creates double joins (from the issue)
            problematic_query = ::Visitor.includes(:automated_campaign_receipts)
                                         .where(automated_campaign_receipts: { automated_campaign_id: campaign.id })
                                         .ransack(automated_campaign_receipts_event_type_eq: 'clicked')
                                         .result

            # Compare the SQL generated when using pluck
            # The issue only manifests when pluck is called
            
            # First, create a helper to extract SQL from pluck operations
            def capture_pluck_sql(relation)
              # Monkey patch to capture the SQL before pluck executes
              original_connection_method = relation.method(:connection)
              captured_sql = nil
              
              relation.define_singleton_method(:connection) do
                conn = original_connection_method.call
                conn.define_singleton_method(:select_all) do |arel, name = nil, binds = [], **kwargs|
                  captured_sql = arel.respond_to?(:to_sql) ? arel.to_sql : arel.to_s
                  super(arel, name, binds, **kwargs)
                end
                conn
              end
              
              relation.pluck(:id)
              captured_sql
            end

            # Now capture SQL for both queries
            correct_sql = capture_pluck_sql(correct_query)
            problematic_sql = capture_pluck_sql(problematic_query)

            # Extract join information
            correct_joins = correct_sql&.scan(/LEFT OUTER JOIN.*?automated_campaign_receipts.*?ON.*?(?=LEFT OUTER JOIN|\sWHERE|\sORDER|\sLIMIT|\z)/mi) || []
            problematic_joins = problematic_sql&.scan(/LEFT OUTER JOIN.*?automated_campaign_receipts.*?ON.*?(?=LEFT OUTER JOIN|\sWHERE|\sORDER|\sLIMIT|\z)/mi) || []

            # The bug is that the problematic query creates more joins than the correct one
            # This test should fail, showing the double-join issue
            expect(problematic_joins.length).to be <= correct_joins.length,
              "Expected problematic query to have same or fewer joins, but got:\n" +
              "Correct query joins: #{correct_joins.length}\n" +
              "Problematic query joins: #{problematic_joins.length}\n" +
              "Correct SQL: #{correct_sql}\n" +
              "Problematic SQL: #{problematic_sql}"
          end
        end
      end
    end
  end
end