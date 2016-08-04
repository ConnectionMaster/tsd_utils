module TsdUtils
  # class for manipulating runtime config
  class RuntimeConfig
    class << self
      def array_to_hash(runtime_config_array)
        runtime_config_array.each_with_object({}) do |input, result|
          stringified = input.deep_stringify_keys.deep_downcase_keys
          if stringified['definition'].casecmp('iniConfiguration').zero?
            result['iniConfiguration'] = stringified['value']
          else
            result[stringified['definition']] = stringified['value']
          end
        end
      end

      def merge(base, override)
        merged = override.dup

        base.each_with_object(merged) do |(key, value), result|
          result[key] = value unless override.ikey?(key)
        end
      end

      def expand_moustache(runtime_config, builder)
        runtime_config.each_with_object({}) do |(k, v), result|
          result[k] = builder.build(v.to_s)
        end
      end

      def build(ini_file, runtime_config)
        builder = Tsd::Builder.new(ini_file, runtime_config)

        built_runtime_config = runtime_config

        max_iterations = runtime_config.keys.count
        (1..max_iterations).each do
          altered_runtime_config = expand_moustache(built_runtime_config, builder)
          builder = Tsd::Builder.new(ini_file, altered_runtime_config)

          break if altered_runtime_config == built_runtime_config
          built_runtime_config = altered_runtime_config
        end

        built_runtime_config
      end
    end
  end
end
