class CreateAllTables < ActiveRecord::Migration[7.0]
  def change
    create_table :people, force: true do |t|
      t.integer  :parent_id
      t.string   :name
      t.string   :email
      t.string   :only_search
      t.string   :only_sort
      t.string   :only_admin
      t.string   :new_start
      t.string   :stop_end
      t.integer  :salary
      t.integer  :temperament
      t.date     :life_start
      t.boolean  :awesome, default: false
      t.boolean  :terms_and_conditions, default: false
      t.boolean  :true_or_false, default: true
      t.timestamps null: false
    end

    create_table :articles, force: true do |t|
      t.integer  :person_id
      t.string   :title
      t.text     :subject_header
      t.text     :body
      t.string   :type
      t.boolean  :published, default: true
    end

    create_table :comments, force: true do |t|
      t.integer  :article_id
      t.integer  :person_id
      t.text     :body
      t.boolean  :disabled, default: false
    end

    create_table :tags, force: true do |t|
      t.string   :name
    end

    create_table :articles_tags, force: true, id: false do |t|
      t.integer  :article_id
      t.integer  :tag_id
    end

    create_table :notes, force: true do |t|
      t.integer  :notable_id
      t.string   :notable_type
      t.string   :note
    end

    create_table :recommendations, force: true do |t|
      t.integer  :person_id
      t.integer  :target_person_id
      t.integer  :article_id
    end

    create_table :accounts, force: true do |t|
      t.belongs_to :agent_account
      t.belongs_to :trade_account
    end

    create_table :addresses, force: true do |t|
      t.string :city
    end

    create_table :organizations, force: true do |t|
      t.string :name
      t.integer :address_id
    end

    create_table :employees, force: true do |t|
      t.string :name
      t.integer :organization_id
    end
  end
end