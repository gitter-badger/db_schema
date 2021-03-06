module DbSchema
  module Utils
    class << self
      def rename_keys(hash, mapping = {})
        hash.reduce({}) do |final_hash, (key, value)|
          new_key = mapping.fetch(key, key)
          final_hash.merge(new_key => value)
        end.tap do |final_hash|
          yield(final_hash) if block_given?
        end
      end

      def filter_by_keys(hash, *needed_keys)
        hash.reduce({}) do |final_hash, (key, value)|
          if needed_keys.include?(key)
            final_hash.merge(key => value)
          else
            final_hash
          end
        end
      end

      def delete_at(hash, *keys)
        keys.map do |key|
          hash.delete(key)
        end
      end

      def symbolize_keys(hash)
        return hash unless hash.is_a?(Hash)

        hash.reduce({}) do |new_hash, (key, value)|
          new_hash.merge(key.to_sym => symbolize_keys(value))
        end
      end

      def sort_by_class(array, sorted_classes)
        sorted_classes.flat_map do |klass|
          array.select { |object| object.is_a?(klass) }
        end
      end

      def filter_by_class(array, klass)
        array.select do |element|
          element.is_a?(klass)
        end
      end
    end
  end
end
