require 'spec_helper'

module Ransack::ActiveRecord
  describe Dialect do
    let(:abstract) { ::ActiveRecord::ConnectionAdapters::AbstractAdapter }

    # Stand-ins for Rails' adapters, named as Rails names them, so the specs
    # do not need every database driver installed.
    let(:postgresql_adapter) { stub_adapter('ActiveRecord::ConnectionAdapters::PostgreSQLAdapter', abstract) }
    let(:mysql_adapter) { stub_adapter('ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter', abstract) }
    let(:sqlite_adapter) { stub_adapter('ActiveRecord::ConnectionAdapters::SQLite3Adapter', abstract) }

    def stub_adapter(name, parent)
      Class.new(parent).tap { |klass| stub_const(name, klass) }
    end

    describe '.detect' do
      it 'recognises the three adapters Ransack knows' do
        expect(Dialect.detect(postgresql_adapter)).to eq :postgresql
        expect(Dialect.detect(mysql_adapter)).to eq :mysql
        expect(Dialect.detect(sqlite_adapter)).to eq :sqlite
      end

      # activerecord-postgis-adapter names itself "PostGIS" but subclasses
      # PostgreSQLAdapter; mysql2 and trilogy both subclass
      # AbstractMysqlAdapter. Ancestry, not the name, decides.
      it 'classifies a subclass of a known adapter with its parent' do
        postgis = Class.new(postgresql_adapter) { const_set(:ADAPTER_NAME, 'PostGIS') }
        trilogy = Class.new(mysql_adapter) { const_set(:ADAPTER_NAME, 'Trilogy') }

        expect(Dialect.detect(postgis)).to eq :postgresql
        expect(Dialect.detect(trilogy)).to eq :mysql
      end

      it 'falls back to generic for an adapter it does not know' do
        sqlserver = Class.new(abstract) { const_set(:ADAPTER_NAME, 'SQLServer') }

        expect(Dialect.detect(sqlserver)).to eq :generic
      end
    end

    describe '.for' do
      it 'reads the dialect from the model connection' do
        expect(Dialect.for(Person).name).to eq Dialect.detect(Person.adapter_class)
      end

      # A model on a second database of a different kind must get that
      # database's dialect, not the primary connection's (#1407).
      it 'reads the searched model, not ActiveRecord::Base' do
        # Whatever the suite's database is, give Person a different one.
        other = Dialect.for(::ActiveRecord::Base).mysql? ? sqlite_adapter : mysql_adapter
        allow(Person).to receive(:adapter_class).and_return(other)

        expect(Dialect.for(Person)).to eq Dialect.new(Dialect.detect(other))
        expect(Dialect.for(Person)).not_to eq Dialect.for(::ActiveRecord::Base)
      end

      it 'is overridden by config.dialect' do
        Ransack.configure { |c| c.dialect = :generic }
        expect(Dialect.for(Person)).to be_generic
      ensure
        Ransack.configure { |c| c.dialect = nil }
      end

      it 'rejects a dialect it does not know' do
        expect { Dialect.new(:oracle) }.to raise_error(ArgumentError, /Unknown dialect :oracle/)
      end
    end

    describe '#case_insensitive_like?' do
      it 'is true only for PostgreSQL, which has ILIKE' do
        expect(Dialect.new(:postgresql)).to be_case_insensitive_like
        expect(Dialect.new(:mysql)).not_to be_case_insensitive_like
        expect(Dialect.new(:sqlite)).not_to be_case_insensitive_like
        expect(Dialect.new(:generic)).not_to be_case_insensitive_like
      end
    end

    describe '#length_function' do
      it 'uses CHAR_LENGTH where it exists and LENGTH elsewhere' do
        expect(Dialect.new(:postgresql).length_function).to eq 'CHAR_LENGTH'
        expect(Dialect.new(:mysql).length_function).to eq 'CHAR_LENGTH'
        expect(Dialect.new(:sqlite).length_function).to eq 'LENGTH'
        expect(Dialect.new(:generic).length_function).to eq 'LENGTH'
      end
    end
  end
end
