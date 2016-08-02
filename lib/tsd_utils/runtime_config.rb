module TsdUtils
  # class for manipulating runtime config
  class RuntimeConfig
    class << self
      def array_to_hash(runtime_config_array)
        runtime_config_array.each_with_object({}) do |input, result|
          stringified = input.deep_stringify_keys.deep_downcase_keys
          # rubocop:disable NumericPredicate
          if stringified['definition'].casecmp('iniConfiguration') == 0
            result['iniConfiguration'] = stringified['value']
          else
            result[stringified['definition']] = stringified['value']
          end
          # rubocop:enable NumericPredicate
        end
      end
    end
  end
end
