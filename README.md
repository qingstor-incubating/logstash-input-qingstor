#Logstash Input Plugin for QingStor

This is a  Logstash Input Plugin for QingStor - a object storage service in QingCloud, referencing the [s3 plugin](https://github.com/logstash-plugins/logstash-input-s3). Now it is a Just Running State, we still need time to improve it.

# configs for this plugin 
```ruby
  # The key id to access your QingStor
  config :access_key_id, :validate => :string, :required => true

  # The key to access your QingStor
  config :secret_access_key, :validate => :string, :required => true

  # The name of the qingstor bucket
  config :bucket, :validate => :string, :required => true

  # The region of the QingStor bucket
  config :region, :validate => :string, :required => true

  # The prefix of filenames
  config :prefix, :validate => :string, :default => nil

  # If this set to true, the file will be deleted after processing
  config :delete_later, :validate => :boolean, :default => false
  
  # If this set to true, the file will backup to a local dir,
  # please make sure you can access to this dir.
  config :local_dir, :validate => :string, :default => nil

  # If specified, the file will be upload to this bucket of the given region
  config :backup_bucket, :validate => :string, :default => nil
  config :backup_region, :validate => :string, :default => nil

  # This prefix will add before backup filename.
  config :backup_prefix, :validate => :string, :default => nil
  
  # Use sincedb to record the last downloas time 
  config :sincedb_path, :validate => :string, :default => nil 
``` 

# Logstash Plugin

This is a plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

Logstash provides infrastructure to automatically generate documentation for this plugin. We use the asciidoc format to write documentation so any comments in the source code will be first converted into asciidoc and then into html. All plugin documentation are placed under one [central location](http://www.elastic.co/guide/en/logstash/current/).

- For formatting code or config example, you can use the asciidoc `[source,ruby]` directive
- For more asciidoc formatting tips, see the excellent reference here https://github.com/elastic/docs#asciidoc-guide

## Need Help?

Need help? Try #logstash on freenode IRC or the https://discuss.elastic.co/c/logstash discussion forum.

## Developing

### 1. Plugin Developement and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Create a new plugin or clone and existing from the GitHub [logstash-plugins](https://github.com/logstash-plugins) organization. We also provide [example plugins](https://github.com/logstash-plugins?query=example).

- Install dependencies
```sh
bundle install
```

#### 2.1 Run in a local Logstash clone

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-filter-awesome", :path => "/your/local/logstash-filter-awesome"
```
- Install plugin
```sh
bin/logstash-plugin install --no-verify
```
- Run Logstash with your plugin
```sh
bin/logstash -e 'filter {awesome {}}'
```
At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-filter-awesome.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/logstash-plugin install /your/local/plugin/logstash-filter-awesome.gem
```
- Start Logstash and proceed to test the plugin

## Contributing to Logstash

All contributions are welcome: ideas, patches, documentation, bug reports, complaints, and even something you drew up on a napkin.

Programming is not a required skill. Whatever you've seen about open source and maintainers or community members  saying "send patches or die" - you will not see that here.

It is more important to the community that you are able to contribute.

For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.
