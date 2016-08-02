module TsdUtils
  # Class for validating clusters
  class ClusterValidator
    attr_reader :errors

    def initialize(clusters)
      @clusters = clusters
    end

    def valid?
      if TsdUtils.config.nil? || TsdUtils.config[:clusters].nil?
        raise 'TsdUtils are not configured properly to validate clusters.'
      end

      @errors = []
      validate_presence_of_single_cluster
      validate_cluster_support
      @errors.empty?
    end

    private

    def validate_presence_of_single_cluster
      if @clusters.length != 1
        @errors << ValidationIssue.new('cluster',
                                       "One cluster allowed, found: #{@clusters}.")
      end
    end

    def validate_cluster_support
      @clusters.each do |cluster|
        if TsdUtils.config[:clusters][cluster.to_sym].nil?
          @errors << ValidationIssue.new('cluster',
                                         "\"#{cluster}\" is not a supported cluster.")
        end
      end
    end
  end
end
