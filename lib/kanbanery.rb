require 'active_resource'
require 'active_support/core_ext/module/attribute_accessors'

module Kanbanery
  mattr_accessor :api_token

  class Resource < ActiveResource::Base
    self.site = "https://kanbanery.com/api/v1"

    def self.headers
      headers = super
      headers['X-Kanbanery-ApiToken'] = Kanbanery.api_token or raise "You must set Kanbanery.api_token to your API token"
      headers
    end

    def to_xml(options={})
      super(options.merge(:except => self.class.readonly_fields))
    end
  end

  class Task < Resource
    def self.readonly_fields
      [:creator_id, :owner_id, :blocked, :created_at, :updated_at, :moved_at]
    end
  end

end
