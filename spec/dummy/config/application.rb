require 'rails/all'

Bundler.require(*Rails.groups)
require "ransack"

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f

    # For compatibility with applications that use this config
    config.active_record.sqlite3_adapter_strict_strings_by_default = false if Rails.version >= "7.0"
  end
end