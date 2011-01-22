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

    def self.belongs_to(parent_name)
      self.class_eval <<-EOS
        def #{parent_name}
          @#{parent_name} ||= #{parent_name.to_s.classify}.find(#{parent_name}_id)
        end

        self.prefix = "#{site.path}/#{parent_name.to_s.pluralize}/:#{parent_name}_id/"

        def self.element_path(id, prefix_options = {}, query_options = nil)
          prefix_options, query_options = split_options(prefix_options) if query_options.nil?
          # prefix_options.merge!(:account_code => id) if id
          if id
            "#{site.path}/\#{collection_name}/\#{URI.escape id.to_s}.\#{format.extension}\#{query_string(query_options)}"
          else
            "\#{prefix(prefix_options)}\#{collection_name}.\#{format.extension}\#{query_string(query_options)}"
          end
        end
EOS
    end

    def self.has_many(children)
      self.class_eval <<-EOS
        def #{children}
          @#{children} ||= #{children.to_s.singularize.classify}.all(:params => { :#{self.to_s.split("::").last.underscore}_id => id })
        end
EOS
    end

    def to_xml(options={})
      except = self.class.readonly_fields
      except << :created_at
      except << :updated_at
      super(options.merge(:except => except))
    end
  end

  class Workspace < Resource
    self.prefix = "#{site.path}/user/"
  end

  class Project < Resource
    belongs_to :workspace
    has_many :columns
  end

  class Column < Resource
    belongs_to :project
    has_many :tasks
  end

  class Task < Resource
    belongs_to :column
    has_many :comments
    has_many :subtasks
    has_many :issues

    def self.readonly_fields
      [:creator_id, :owner_id, :blocked, :created_at, :updated_at, :moved_at]
    end
  end

  class Comment < Resource
    belongs_to :task

    def self.readonly_fields
      [:author_id, :task_id]
    end
  end

  class Subtask < Resource
    belongs_to :task

    def self.readonly_fields
      [:creator_id, :task_id]
    end
  end

  class Issue < Resource
    belongs_to :task

    def self.readonly_fields
      [:task_id]
    end
  end

end
