module DbSchema
  class DSL
    attr_reader :block

    def initialize(block)
      @block  = block
      @schema = Definitions::Schema.new
    end

    def schema
      block.call(self)

      @schema
    end

    def table(name, &block)
      table_yielder = TableYielder.new(name, block)

      @schema.tables << Definitions::Table.new(
        name,
        fields:       table_yielder.fields,
        indices:      table_yielder.indices,
        checks:       table_yielder.checks,
        foreign_keys: table_yielder.foreign_keys
      )
    end

    def enum(name, values)
      @schema.enums << Definitions::Enum.new(name.to_sym, values.map(&:to_sym))
    end

    def extension(name)
      @schema.extensions << Definitions::Extension.new(name.to_sym)
    end

    class TableYielder
      attr_reader :table_name

      def initialize(table_name, block)
        @table_name = table_name
        block.call(self)
      end

      DbSchema::Definitions::Field.registry.keys.each do |type|
        define_method(type) do |name, **options|
          field(name, type, options)
        end
      end

      def method_missing(method_name, name, *args, &block)
        field(name, method_name, args.first || {})
      end

      def primary_key(name)
        field(name, :integer, primary_key: true)
      end

      def index(*columns, name: nil, unique: false, using: :btree, where: nil, **ordered_fields)
        if columns.last.is_a?(Hash)
          *ascending_columns, ordered_expressions = columns
        else
          ascending_columns = columns
          ordered_expressions = {}
        end

        columns_data = ascending_columns.each_with_object({}) do |column_name, columns|
          columns[column_name] = :asc
        end.merge(ordered_fields).merge(ordered_expressions)

        index_columns = columns_data.map do |column_name, column_order_options|
          options = case column_order_options
          when :asc
            {}
          when :desc
            { order: :desc }
          when :asc_nulls_first
            { nulls: :first }
          when :desc_nulls_last
            { order: :desc, nulls: :last }
          else
            raise ArgumentError, 'Only :asc, :desc, :asc_nulls_first and :desc_nulls_last options are supported.'
          end

          if column_name.is_a?(String)
            Definitions::Index::Expression.new(column_name, **options)
          else
            Definitions::Index::TableField.new(column_name, **options)
          end
        end

        index_name = name || "#{table_name}_#{index_columns.map(&:index_name_segment).join('_')}_index"

        indices << Definitions::Index.new(
          name:      index_name,
          columns:   index_columns,
          unique:    unique,
          type:      using,
          condition: where
        )
      end

      def check(name, condition)
        checks << Definitions::CheckConstraint.new(name: name, condition: condition)
      end

      def foreign_key(*fkey_fields, references:, name: nil, on_update: :no_action, on_delete: :no_action, deferrable: false)
        fkey_name = name || :"#{table_name}_#{fkey_fields.first}_fkey"

        if references.is_a?(Array)
          # [:table, :field]
          referenced_table, *referenced_keys = references

          foreign_keys << Definitions::ForeignKey.new(
            name:       fkey_name,
            fields:     fkey_fields,
            table:      referenced_table,
            keys:       referenced_keys,
            on_delete:  on_delete,
            on_update:  on_update,
            deferrable: deferrable
          )
        else
          # :table
          foreign_keys << Definitions::ForeignKey.new(
            name:       fkey_name,
            fields:     fkey_fields,
            table:      references,
            on_delete:  on_delete,
            on_update:  on_update,
            deferrable: deferrable
          )
        end
      end

      def field(name, type, custom: false, unique: false, index: false, references: nil, check: nil, **options)
        fields << Definitions::Field.build(name, type, options)

        if unique
          index(name, unique: true)
        elsif index
          index(name)
        end

        if references
          foreign_key(name, references: references)
        end

        if check
          check("#{table_name}_#{name}_check", check)
        end
      end

      def fields
        @fields ||= []
      end

      def indices
        @indices ||= []
      end

      def checks
        @checks ||= []
      end

      def foreign_keys
        @foreign_keys ||= []
      end
    end
  end
end
