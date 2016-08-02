module TsdUtils
  # Validation encapsulation
  class TestValidator
    def initialize(tsd, clusters)
      @tsd_validator = TsdUtils::TsdValidator.new(tsd.tsd.to_json)
      @cluster_validator = TsdUtils::ClusterValidator.new(clusters)
    end

    def valid?
      [@tsd_validator, @cluster_validator].map(&:valid?).all?
    end

    def errors
      valid?
      @tsd_validator.errors + @cluster_validator.errors
    end
  end
end
