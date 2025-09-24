require 'spec_helper'

module Ransack
  module Adapters
    module ActiveRecord
      describe 'Double join issue with pluck' do
        context 'when using pluck with ransack on already joined query' do
          it 'creates erroneous double-join when using pluck with ransack' do
            # Create test data to match the scenario from the issue
            campaign = ::AutomatedCampaign.create!(name: 'Test Campaign')
            visitor = ::Visitor.create!(name: 'Test Visitor')
            ::AutomatedCampaignReceipt.create!(
              visitor: visitor, 
              automated_campaign: campaign, 
              event_type: 'clicked'
            )

            # Capture SQL for both approaches by enabling SQL logging
            queries = []
            callback = lambda do |name, started, finished, unique_id, payload|
              queries << payload[:sql] if payload[:sql] && payload[:sql].include?('SELECT')
            end

            # Subscribe to SQL events
            ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
              # First approach: Standard ActiveRecord (should produce 1 join)
              queries.clear
              result1 = ::Visitor.includes(:automated_campaign_receipts)
                                 .where(automated_campaign_receipts: { automated_campaign_id: campaign.id })
                                 .where(automated_campaign_receipts: { event_type: 'clicked' })
                                 .pluck(:id)

              base_sql = queries.last

              # Second approach: Using ransack (may produce double join according to issue)
              queries.clear
              result2 = ::Visitor.includes(:automated_campaign_receipts)
                                 .where(automated_campaign_receipts: { automated_campaign_id: campaign.id })
                                 .ransack(automated_campaign_receipts_event_type_eq: 'clicked')
                                 .result
                                 .pluck(:id)

              ransack_sql = queries.last
              
              # Extract and compare joins
              base_joins = base_sql&.scan(/LEFT OUTER JOIN.*?automated_campaign_receipts.*?ON.*?(?=LEFT OUTER JOIN|\sWHERE|\s(?:GROUP|ORDER|LIMIT|$))/mi) || []
              ransack_joins = ransack_sql&.scan(/LEFT OUTER JOIN.*?automated_campaign_receipts.*?ON.*?(?=LEFT OUTER JOIN|\sWHERE|\s(?:GROUP|ORDER|LIMIT|$))/mi) || []

              puts "\n=== PLUCK SQL COMPARISON ==="
              puts "Base query SQL (#{base_joins.length} joins): #{base_sql}"
              puts "Ransack query SQL (#{ransack_joins.length} joins): #{ransack_sql}"
              puts "Base joins found: #{base_joins.inspect}"
              puts "Ransack joins found: #{ransack_joins.inspect}"

              # The issue reports that ransack creates duplicate joins with pluck
              # If this test fails, it reproduces the issue described
              expect(ransack_joins.length).to eq(base_joins.length), 
                "Expected same number of joins, but ransack created #{ransack_joins.length} vs #{base_joins.length} in base query"

              # Results should be the same
              expect(result2).to eq(result1)
            end
          end

          it 'demonstrates the difference with and without pluck' do
            # Create test data
            campaign = ::AutomatedCampaign.create!(name: 'Test Campaign 2')
            visitor = ::Visitor.create!(name: 'Test Visitor 2')
            ::AutomatedCampaignReceipt.create!(
              visitor: visitor, 
              automated_campaign: campaign, 
              event_type: 'clicked'
            )

            # Set up the base query
            base_query = ::Visitor.includes(:automated_campaign_receipts)
                                  .where(automated_campaign_receipts: { automated_campaign_id: campaign.id })

            # Add ransack condition
            ransack_query = base_query.ransack(automated_campaign_receipts_event_type_eq: 'clicked').result

            # Compare SQL without pluck (should be similar)
            base_sql = base_query.to_sql
            ransack_sql = ransack_query.to_sql

            puts "\n=== WITHOUT PLUCK ==="  
            puts "Base SQL: #{base_sql}"
            puts "Ransack SQL: #{ransack_sql}"

            base_join_count = base_sql.scan(/LEFT OUTER JOIN.*automated_campaign_receipts/i).count
            ransack_join_count = ransack_sql.scan(/LEFT OUTER JOIN.*automated_campaign_receipts/i).count

            puts "Base joins: #{base_join_count}, Ransack joins: #{ransack_join_count}"

            # This comparison shows the issue is specifically with pluck
            expect(ransack_join_count).to be >= base_join_count
          end
        end
      end
    end
  end
end