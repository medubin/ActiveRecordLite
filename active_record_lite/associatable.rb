require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    if self.is_a?(BelongsToOptions)
      foreign_key.to_s[0..-4].classify.constantize.table_name
    elsif self.is_a?(HasManyOptions)
      class_name.constantize.table_name
    end
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || (name.to_s.underscore + '_id').to_sym
    @primary_key = options[:primary_key] || :id
    @class_name =  options[:class_name]  || name.to_s.singularize.camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || (self_class_name.underscore + '_id').to_sym
    @primary_key = options[:primary_key] || :id
    @class_name =  options[:class_name]  || name.singularize.camelcase

  end
end

module Associatable
  def belongs_to(name, options = {})
    self.assoc_options[name] =  BelongsToOptions.new(name, options)
    opts = BelongsToOptions.new(name, options)


    define_method(name) do
      opts.model_class.where(opts.primary_key => self.send(opts.foreign_key)).first
    end

  end

  def has_many(name, options = {})
    opts = HasManyOptions.new(name.to_s, self.to_s, options)

      define_method(name) do
        opts.model_class.where(opts.foreign_key => self.send(opts.primary_key))
    end
  end

  def assoc_options
    @assoc_options ||= {}

  end
end

class SQLObject
  extend Associatable
end
