require 'json'
require 'tsd_utils/tsd/builder'
require 'tsd_utils/content_fetcher'
require 'tsd_utils/runtime_config'

module TsdUtils
  # Class represeting TSD
  class Tsd
    # Class for normalizing package format
    class PackageProviderNormalizer
      def initialize(package)
        PackageProvider::Parser.parse(package)
      end
    end

    attr_accessor :tsd

    def initialize
      @runtime_config = {}
      @tsd = nil
    end

    def load_uri(uri)
      begin
        cont = ContentFetcher.load(uri)
      rescue URI::InvalidURIError
        cont = ContentFetcher.load(URI.encode(uri))
      end

      @tsd = JSON.parse(cont.encode('ASCII', undef: :replace, replace: ''))
    end

    def load_content(content)
      @tsd = JSON.parse(content)
    end

    def runtime_config
      TsdUtils::RuntimeConfig.array_to_hash(@tsd['runtimeConfig'] || [])
    end

    def package_povider=(p)
      @package_provider = p
    end

    def build(custom_runtime_config = nil)
      build_tsd(custom_runtime_config || {})
    end

    def normalize_clusters
      @tsd['environment']['machines'].each do |m|
        cluster, template = m['id'].split('.', 2)
        m.merge!(
          'cluster' => cluster,
          'id' => template
        ) if known_clusters.include?(cluster.downcase) && m['cluster'].nil?
      end
    end

    private

    def build_runtime_config(builder)
      return unless @tsd['runtimeConfig']

      @tsd['runtimeConfig'].each_with_object([]) do |item, result|
        result << {
          'definition' => item['definition'],
          'value' => builder.build(item['value'])
        }
      end
    end

    def build_tsd(merged_runtime_config)
      ini_file = merged_runtime_config.get_ikey('iniConfiguration')
      builder = Builder.new(ini_file, merged_runtime_config)

      mustached_tsd = JSON.parse(builder.build(JSON.pretty_generate(@tsd)))
      mustached_tsd['runtimeConfig'] = build_runtime_config(builder)

      JSON.pretty_generate(mustached_tsd)
    end

    def known_clusters
      @known_clusters ||= TsdUtils.config[:clusters].keys.map(&:to_s)
    end
  end
end
