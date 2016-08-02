require 'httparty'
require 'uri'

module TsdUtils
  # Class for downloading file from stash
  class Stash
    class << self
      def fetch_file(uri_string)
        params = {
          basic_auth: {
            username: ENV['STASH_USER'],
            password: ENV['STASH_PASSWORD']
          }
        }

        uri = URI(uri_string)
        new_query_ar = URI.decode_www_form(uri.query || '').to_h
        new_query_ar['raw'] = '' unless new_query_ar['raw']

        uri.query = URI.encode_www_form(new_query_ar)
        HTTParty.get(uri.to_s, params).body
      end

      def stash_https_link?(uri_string)
        uri = URI(uri_string)
        return true if uri.scheme == 'https' && uri.host.to_s.match('stash')
        false
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
