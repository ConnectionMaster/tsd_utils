module TsdUtils
  # Descriptor for validation issues
  class ValidationIssue
    attr_reader :context
    attr_reader :description

    def initialize(context, description)
      @context = context
      @description = description
    end
  end
end
