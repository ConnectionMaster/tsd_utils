require 'iniparse'
require 'json'
require 'mustache'

module TsdUtils
  # Class represeting TSD
  class Tsd
    # Class for replacing ini config or runtime config values in TSD
    class Builder < Mustache
      attr_reader :runtime_config

      def initialize(ini_file, runtime_config)
        @ini_file = ini_file

        @runtime_config = runtime_config
        @expanded_runtime_config = nil
      end

      def ini_file_data
        return @ini_file_data if @ini_file_data

        @ini_file_data = {}
        return @ini_file_data unless @ini_file

        ini_file_content = ContentFetcher.load(@ini_file)
        @ini_file_data = IniParse.parse(ini_file_content).to_hash
      end

      def expanded_runtime_config
        return @expanded_runtime_config if @expanded_runtime_config
        vars = {
          runtimeConfig: @runtime_config,
          runtimeconfig: @runtime_config,
          Runtimeconfig: @runtime_config,
          RuntimeConfig: @runtime_config,
          ini: ini_file_data.to_hash
        }

        t = Mustache.render(@runtime_config.to_json, vars)
        @expanded_runtime_config = JSON.parse(t)
      end

      def method_missing(method, *args)
        super unless args.empty?
        ini_file_data[method] || expanded_runtime_config[method]
      end

      def respond_to_missing?(_, _)
        true
      end

      def build(tsd)
        vars = {
          runtimeConfig: expanded_runtime_config,
          runtimeconfig: expanded_runtime_config,
          Runtimeconfig: expanded_runtime_config,
          RuntimeConfig: expanded_runtime_config,
          ini: ini_file_data.to_hash
        }

        Mustache.render(tsd, vars)
      end
    end
  end
end
