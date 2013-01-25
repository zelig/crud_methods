require 'state_methods'
require 'active_support/core_ext/module/attribute_accessors'

module CrudMethods

  ACTIONS = { :C => [:create!, :new!], :U => [:edit!, :update!], :D => [:destroy!], :R => [:show!, :index!] }
  mattr_accessor :actions
  @@actions = ACTIONS
  DEFAULT_ACTIONS = [:new, :create, :edit, :update, :show, :index, :destroy]
  mattr_accessor :default_actions
  @@default_actions = DEFAULT_ACTIONS
  mattr_accessor :default_extension
  @@default_extension = {}
  default_actions.each { |a| default_extension[:"#{a}!"] = a }


  module Controller

    def self.included(base)
      base.class_eval do
        include ::StateMethods
        _state_partition_for :action_name, :partition => ::CrudMethods.actions
        include ControllerInstanceMethods
        extend ControllerClassMethods
      end
    end

    module ControllerInstanceMethods

    end

    module ControllerClassMethods

      def crud_actions(*args)
        args.each do |spec|
          spec = ::CrudMethods.default_extension if spec == :defaults
          puts spec
          _state_partition_for :action_name, :extend => spec
        end
        puts _state_partition_for(:action_name).index
      end

      def crud_method(name)
        state_method(name, :action_name)
      end

    end

  end
end
