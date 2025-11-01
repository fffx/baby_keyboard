source "https://rubygems.org"
ruby "3.4.5"

# ruby 3.4 dependencies, see https://github.com/fastlane/fastlane/issues/29183
gem "abbrev"
gem "mutex_m"
gem "ostruct"

gem "fastlane"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
