# TsdUtils

Library used by Final-CI subsystems to perform operations related to TSD. TSD is an abbreviation for
Test Suite Definition, and it is a custom, json based file format, used to describe the automated test.

The library allows both TSD validation and conversion to another data format,
which can be used to launch a build. Some auxiliary functions, such as unc/url content fetcher
are offered as part of this gem as well

The validation of data is currently solved by calling custom external executable,
to not further bloat the TsdUtils code.

This library depends on smbget application that si required for downloading content
from unc paths.

## Installation

Add this line to your application's Gemfile:

```ruby
git: github: 'AVGTechnologies/tsd_utils'
```

And then execute:
```
$ bundle
```

## Usage

Gem requires cluster endpoint specifications for proper resolving. You can setup cluster by calling:

```ruby
TsdUtils.config = {
  clusters: [
    { cluster1: 'endpoint1' },
    { cluster2: 'endpoint2' }
  ]
  executable: 'TsdValidator',
  executable_params: '-param'
}
```

Gem works with several environment properties:

```
SMB_USER        # login for UNC
SMB_PASSWORD    # password for UNC
STASH_USER      # login for stash
STASH_PASSWORD  # password for stash
```

Downloading content from UNC or Http

```ruby
url_or_unc_content = TsdUtils::ContentFetcher.load(url_link_or_unc_path)
```

Creating build enqueue data

```ruby
enqueue_data = TsdUtils::EnqueueData.new(payload)
enqueue_data.build_all # builds payload data
enqueue_data.valid?   
enqueue_data.clusters  # resolves clusters
enqueue_data.to_xml    # returns xml formated enqueue data
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AVGTechnologies/tsd_utils.
