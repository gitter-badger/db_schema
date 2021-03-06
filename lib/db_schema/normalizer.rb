require 'digest/md5'

module DbSchema
  class Normalizer
    attr_reader :table

    class << self
      def normalize_tables(schema)
        DbSchema.connection.transaction do
          create_extensions!(schema.extensions)
          create_enums!(schema.enums)

          schema.tables = schema.tables.map do |table|
            if table.has_expressions?
              new(table).normalized_table
            else
              table
            end
          end

          raise Sequel::Rollback
        end
      end

    private
      def create_extensions!(extensions)
        (extensions - DbSchema::Reader.read_extensions).each do |extension|
          operation = DbSchema::Changes::CreateExtension.new(extension.name)
          DbSchema::Runner.new([operation]).run!
        end
      end

      def create_enums!(enums)
        existing_enums_names = DbSchema::Reader.read_enums.map(&:name)
        enums.each do |enum|
          next if existing_enums_names.include?(enum.name)

          operation = DbSchema::Changes::CreateEnum.new(enum.name, enum.values)
          DbSchema::Runner.new([operation]).run!
        end
      end
    end

    def initialize(table)
      @table = table
    end

    def normalized_table
      create_temporary_table!
      read_temporary_table
    end

  private
    def create_temporary_table!
      operation = Changes::CreateTable.new(
        temporary_table_name,
        fields:  table.fields,
        indices: rename_indices(table.indices),
        checks:  table.checks
      )

      Runner.new([operation]).run!
    end

    def read_temporary_table
      temporary_table = Reader.read_table(temporary_table_name)

      Definitions::Table.new(
        remove_hash(temporary_table.name),
        fields:       temporary_table.fields,
        indices:      rename_indices_back(temporary_table.indices),
        checks:       temporary_table.checks,
        foreign_keys: table.foreign_keys
      )
    end

    def rename_indices(indices)
      indices.map do |index|
        Definitions::Index.new(
          name:      append_hash(index.name),
          columns:   index.columns,
          unique:    index.unique?,
          type:      index.type,
          condition: index.condition
        )
      end
    end

    def rename_indices_back(indices)
      indices.map do |index|
        Definitions::Index.new(
          name:      remove_hash(index.name),
          columns:   index.columns,
          unique:    index.unique?,
          type:      index.type,
          condition: index.condition
        )
      end
    end

    def temporary_table_name
      append_hash(table.name)
    end

    def append_hash(name)
      "#{name}_#{hash}"
    end

    def remove_hash(name)
      name.to_s.sub(/_#{Regexp.escape(hash)}$/, '').to_sym
    end

    def hash
      @hash ||= begin
        names = [table.name] + table.fields.map(&:name) + table.indices.map(&:name) + table.checks.map(&:name)
        Digest::MD5.hexdigest(names.join(','))[0..9]
      end
    end
  end
end
