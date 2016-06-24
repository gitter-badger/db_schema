require 'spec_helper'

RSpec.describe DbSchema::Validator do
  describe '#valid?' do
    subject { DbSchema::Validator.new(schema) }

    let(:schema) do
      [
        DbSchema::Definitions::Table.new(
          :users,
          fields:       fields,
          indices:      indices,
          checks:       checks,
          foreign_keys: foreign_keys
        )
      ]
    end

    let(:fields) do
      [
        DbSchema::Definitions::Field::Integer.new(:id, primary_key: true),
        DbSchema::Definitions::Field::Varchar.new(:first_name, null: false),
        DbSchema::Definitions::Field::Varchar.new(:last_name, null: false),
        DbSchema::Definitions::Field::Integer.new(:age)
      ]
    end

    let(:indices) do
      [
        DbSchema::Definitions::Index.new(
          name: :users_name_index,
          fields: [
            DbSchema::Definitions::Index::Field.new(:first_name),
            DbSchema::Definitions::Index::Field.new(:last_name)
          ],
          unique: true
        )
      ]
    end

    let(:checks) do
      [
        DbSchema::Definitions::CheckConstraint.new(
          name:      :adult,
          condition: 'age >= 18'
        )
      ]
    end

    let(:foreign_keys) do
      []
    end

    context 'on a valid schema' do
      it 'returns true' do
        expect(subject).to be_valid
      end
    end

    context 'on a schema with index on unknown field' do
      let(:indices) do
        [
          DbSchema::Definitions::Index.new(
            name: :invalid_index,
            fields: [
              DbSchema::Definitions::Index::Field.new(:address)
            ]
          )
        ]
      end

      it 'returns false' do
        expect(subject).not_to be_valid
      end
    end
  end
end