require 'open3'

module TsdUtils
  # Class resolving windows and unix paths
  class SMB
    class SMBReadError < StandardError
    end

    USER = ENV['SMB_USER']
    PASSWORD = ENV['SMB_PASSWORD']

    class << self
      def read(path)
        raise ArgumentError, 'Supply valid UNC path' unless unc?(path)

        Gem.win_platform? == true ? read_unc(path) : read_smb(path)
      end

      def unc?(path)
        return true if path.start_with?('\\\\', '//') # windows network path

        uri = URI.parse(path)
        return true if uri.scheme == 'smb'
        false
      rescue URI::InvalidURIError
        false
      end

      def normalize_unc(path)
        uri = URI.parse(path.tr('\\', '/'))
        uri.scheme = 'smb'
        uri.to_s
      end

      private

      def read_smb(path)
        stdout, stderr, status = Open3.capture3(
          {}, 'smbget', '-q', '-u', USER, '-p', PASSWORD, '-O', normalize_unc(path)
        )

        return stdout if status.success?
        raise SMBReadError, "Could not read UNC: #{path.inspect}, stderr: #{stderr}"
      end

      def read_unc(path)
        File.read(path)
      rescue Errno::ENOENT
        raise SMBReadError, "Could not read UNC: #{path.inspect}"
      end
    end
  end
end
