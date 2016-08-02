require 'tsd_utils/smb'
require 'httparty'
require 'tsd_utils/stash'

module TsdUtils
  # class downloading file content both on windows and unix path
  class ContentFetcher
    def self.load(uri)
      return SMB.read(uri) if SMB.unc?(uri)
      return Stash.fetch_file(uri) if Stash.stash_https_link?(uri)

      HTTParty.get(uri).body
    end
  end
end
