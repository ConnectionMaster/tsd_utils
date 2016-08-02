require 'open3'

module TsdUtils
  # Class for validating TSD content
  class TsdValidator
    attr_writer :tsd
    attr_reader :errors

    def initialize(tsd_string = nil)
      @tsd = tsd_string
    end

    def valid?
      params = [
        'mono',
        "./bin/#{TsdUtils.config[:executable]}",
        TsdUtils.config[:executable_params]
      ]

      @errors = []
      Open3.popen3({}, *params) do |stdin, _stdout, stderr, wait_thread|
        stdin.write @tsd
        stdin.close

        exit_status = wait_thread.value.exitstatus
        valid_flag = exit_status.nil? ? false : exit_status.zero?

        @errors << ValidationIssue.new('tsd', stderr.read.to_s) unless valid_flag
      end

      @errors.empty?
    end
  end
end
