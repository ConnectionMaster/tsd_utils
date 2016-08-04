require 'gyoku'
require 'tsd_utils/runtime_config'
require 'tsd_utils/tsd/builder'
require 'active_support/core_ext/hash/conversions'
require 'tsd_utils/enqueue_data_mapping'

module TsdUtils
  # Class represeting TSD data
  class EnqueueData
    attr_accessor :enqueue_data

    ENQUEUE_DATA_BASE =
      {
        'Id' => nil,
        'Priority' => nil,
        'UseVmci' => nil,
        'Async' => nil,
        'PersistanceStrategy' => nil,
        'WaitForBuildSignal' => nil,
        'Debugging' => nil,
        'BranchMerge' => nil,
        'Token' => nil,
        'ScenarioStrategy' => nil,
        'LabManagerConfiguration' => nil,
        'ImportAfterFinish' => nil,
        'CreateTasks' => nil,
        'GenerateFullTemplate' => nil,
        'TestCaseResponsibility' => nil,
        'StrictTimeout' => nil,
        'BuildId' => -1,
        'Package' => false,
        'UseStartScript' => false,
        'SaveCheckpoints' => false,
        'PackageSource' => nil
      }.freeze

    TsdValidationError = Class.new(ArgumentError)

    def initialize(test_data)
      @enqueue_data = to_enqueue_data(test_data)
      @enqueue_data['enqueueAndStart'] = true
      @tsd = Tsd.new
    end

    def build_all
      load_tsd
      normalize
      resolve_strategy
      build
      resolve_email
    end

    def valid?
      @validator = TestValidator.new(@tsd, clusters) if @validator.nil?
      @validator.valid?
    end

    def errors
      @validator = TestValidator.new(@tsd, clusters) if @validator.nil?
      @validator.errors
    end

    def load_tsd
      unless @enqueue_data['TsdWebgitLink'].to_s.empty?
        return @tsd.load_uri(@enqueue_data['TsdWebgitLink'])
      end

      unless @enqueue_data['TsdContent'].to_s.empty?
        return @tsd.load_content(@enqueue_data['TsdContent'])
      end

      raise 'We are unable to resolve tsd source'
    end

    # rubocop:disable AbcSize
    def build
      normalize_runtime_config

      @enqueue_data['RuntimeConfig'] = RuntimeConfig.merge(@tsd.runtime_config,
                                                           @enqueue_data['RuntimeConfig'])

      ini_file = @enqueue_data['RuntimeConfig'].get_ikey('iniConfiguration')
      @enqueue_data['RuntimeConfig'] =
        RuntimeConfig.build(ini_file, @enqueue_data['RuntimeConfig'])

      builder = Tsd::Builder.new(ini_file, @enqueue_data['RuntimeConfig'])
      @enqueue_data.each do |key, val|
        next if %w(TsdContent RuntimeConfig).include?(key)

        @enqueue_data[key] = builder.build(val.to_s) unless val.nil?
      end

      @enqueue_data['TsdContent'] = @tsd.build @enqueue_data['RuntimeConfig']
    end
    # rubocop:enable AbcSize

    def normalize_package_source
      @enqueue_data['PackageSource'].upcase! if @enqueue_data['PackageSource']
    end

    def resolve_email
      email = @enqueue_data['RuntimeConfig']['email']
      @enqueue_data['Email'] = @enqueue_data['RuntimeConfig']['email'] if email
    end

    def resolve_strategy
      return unless @tsd.tsd['strategy']

      strategy_from_enqueue_data = @enqueue_data['StrategyName']
      strategy_from_runtime_config = @enqueue_data['RuntimeConfig']['strategy']

      [strategy_from_enqueue_data, strategy_from_runtime_config].compact.each do |strategy|
        unless @tsd.tsd['strategy'].select { |s| s['name'] == strategy }.empty?
          @tsd.tsd['defaultStrategy'] = strategy
          break
        end
      end

      @enqueue_data['StrategyName'] = @tsd.tsd['defaultStrategy']
    end

    def normalize
      normalize_runtime_config
      normalize_package_source
      @tsd.normalize_clusters
    end

    def normalize_runtime_config
      return if @enqueue_data['RuntimeConfig'].is_a?(Hash)

      @enqueue_data['RuntimeConfig'] =
        TsdUtils::RuntimeConfig.array_to_hash(@enqueue_data['RuntimeConfig'] || [])
    end

    def to_xml
      enqueue_data = @enqueue_data.duplicate
      enqueue_data.delete('TsdType')
      enqueue_data['RuntimeConfig'] = Gyoku.xml('runtime_config' => enqueue_data['RuntimeConfig'])
      enqueue_data = enqueue_data.each_with_object({}) { |(k, v), memo| memo[k.to_sym] = v }

      data = {
        enqueueData: enqueue_data,
        attributes!: {
          enqueueData: {
            'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
            'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
          }
        }
      }

      str = Gyoku.xml(data, key_converter: :camelcase)
      str.prepend('<?xml version="1.0" encoding="utf-8"?>')
    end

    def clusters
      strategy_environment = selected_strategy['environments']

      clusters = @tsd.tsd['environment']['machines'].each_with_object([]) do |machine, result|
        result << machine['cluster'] if machine_belongs_to(machine['name'], strategy_environment)
      end

      clusters.uniq.compact
    end

    def tsd
      JSON.parse(@enqueue_data['TsdContent'])
    end

    def package_source
      branch = tsd.get_ikey('source')
      @enqueue_data.get_ikey('Branch') || branch.get_ikey('git') || branch.get_ikey('unc')
    end

    def package_from
      package_from = @enqueue_data.get_ikey('PackageSource')
      return package_from.upcase if package_from
      branch = tsd.get_ikey('source')
      return 'GIT' if branch.get_ikey('git')
      return 'UNC' if branch.get_ikey('unc')
    end

    def email
      @enqueue_data.get_ikey('email') || tsd.get_ikey('responsible')
    end

    def description
      resolve_field('description')
    end

    def runtime_config
      runtime_config = @enqueue_data.get_ikey('runtimeConfig')
      return [] if runtime_config.nil?
      runtime_config.each_with_object([]) do |(key, value), array|
        array << { definition: key.to_s, value: value.to_s }
      end
    end

    private

    def resolve_field(field)
      @enqueue_data.get_ikey(field) || tsd.get_ikey(field)
    end

    def to_enqueue_data(test_data)
      test_data = test_data.map { |k, v| [ENQUEUE_DATA_MAPPING[k.downcase] || k, v] }.to_h

      test_data = ENQUEUE_DATA_BASE.merge(test_data)

      id = test_data.delete('RetestId')
      test_data['Id'] = id if id

      test_data
    end

    def machine_belongs_to(machine_name, filter)
      return true unless filter

      negation_count = 0

      filter.each do |r|
        rule = r.dup

        machine_allowed_flag = true

        if rule.start_with? '!'
          negation_count += 1
          rule.slice!(0) # removes '!' from the string beginning

          # '!' negates the rule, so the machine name is not allowed in result
          machine_allowed_flag = false
        end

        return machine_allowed_flag if rule.end_with?('*') && machine_name.start_with?(rule.chop)
        return machine_allowed_flag if machine_name == rule
      end
      # If all rules are starting with '!' then machine with name not mentioned in rules is valid
      # e.g.: filter = ['!XP', '!7']; machines = ['XP', '7', '8'] => returns true only for '8'
      # If there is at least one rule without '!' then machine with this name is only valid
      # e.g.: filter = ['!XP', '7']; machines = ['XP', '7', '8'] => returns true only for '7'
      negation_count == filter.size
    end

    def selected_strategy
      @tsd.tsd['strategy'].find { |s| s['name'] == @tsd.tsd['defaultStrategy'] }
    end
  end
end
