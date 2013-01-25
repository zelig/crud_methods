require 'spec_helper'
require 'crud_methods'

require 'rails'
require 'action_controller/railtie'
require 'rspec/rails'
module TestRailsApp
  class Application < Rails::Application
    # app config here
    # config.secret_token = '572c86f5ede338bd8aba8dae0fd3a326aabababc98d1e6ce34b9f5'
    routes.draw do
      resources :models
      get "unknown" => 'anonymous#unknown'
    end
    # routes are created for anonymous controllers https://www.relishapp.com/rspec/rspec-rails/docs/controller-specs/anonymous-controller#anonymous-controllers-only-create-resource-routes
  end

  class ApplicationController < ActionController::Base
    include CrudMethods::Controller
    crud_method :test
    test(:all) { 0 }
    def default_render
      render :text => @content
    end
  end

  class DefaultTestController < ApplicationController
    extend(RSpec::Rails::ControllerExampleGroup::BypassRescue)
    def self.default_actions
      [:new, :create, :edit, :update, :show, :index, :destroy]
    end
    def self.default_action_types
      default_actions.map { |a| :"#{a}!" }
    end
    default_actions.each do |a|
      define_method(a) {}
    end
    def unknown
    end
  end

end

def default_actions
  TestRailsApp::DefaultTestController.default_actions
end

def default_action_types
  TestRailsApp::DefaultTestController.default_action_types
end

class Error
  def initialize(*args)
    @args = args
  end
  def to_a
    @args
  end
  def to_s
    to_a.join(' with ')
  end
end

def crud_test(action, result, method = :test, *args, &block)
  spec = case result
  when Error
    "when action = #{action} then Controller##{method} raises #{result.to_s}"
  else
    "when action = #{action} then Controller##{method} = #{result}"
  end
  it spec do
    crud_test!(action, result, method, *args, &block)
  end
end

def crud_test!(action, result, method = :test, *args, &block)
  case result
  when Error
    lambda do
      _crud_test(action, result, method, *args, &block)
    end.should raise_error(*result.to_a)
  else
    _crud_test(action, result, method, *args, &block).
      should == result
  end
end

def _crud_test(action, result, method = :test, *args, &block)
  instance_eval(&block) if block_given?
  get action, :id => "anyid"
  puts "controller.action_name: #{controller.action_name}"
  puts "#{controller.class._state_partition_for(:action_name).index}"
  controller.send(method, *args)
end

describe 'CrudMethods' do

  context "in a Rails controller", :type => :controller do

    before(:each) do
      @request = ActionController::TestRequest.new
    end

    describe "default extension" do

      context "crud method 'test' is set on types only" do
        controller(TestRailsApp::DefaultTestController) do
          crud_actions :defaults
          default_action_types.each { |a| test(a) { a } }
        end

        it "falls back to :all if action is undeclared" do
          routes.draw { get "unknown" => 'anonymous#unknown' }
          # lambda { get :unknown }.should raise_error(NameError)
          crud_test!(:unknown, 0)
        end

        default_actions.each do |a|
          crud_test(a, :"#{a}!")
        end
      end

      context "crud method 'test' is set on actions too and override type spec" do
        controller(TestRailsApp::DefaultTestController) do
          crud_actions :defaults
          default_action_types.each { |a| test(a) { a } }
          default_actions.each { |a| test(a) { a } }
        end

        it "falls back to :all if action is undeclared" do
          routes.draw { get "unknown" => 'anonymous#unknown' }
          # lambda { get :unknown }.should raise_error(NameError)
          crud_test!(:unknown, 0)
        end

        default_actions.each do |a|
          crud_test(a, a)
        end
      end
    end

    describe "alternative extensions" do

      context ":index! => [:index, :list]" do

        controller(TestRailsApp::DefaultTestController) do
          crud_actions :index! => [:index, :list]
          default_action_types.each { |a| test(a) { a } }
          def list
          end
        end

        it "falls back to :all if action is undeclared" do
          routes.draw { get "unknown" => 'anonymous#unknown' }
          # lambda { get :unknown }.should raise_error(NameError)
          crud_test!(:unknown, 0)
        end

        crud_test(:index, :"index!")
        crud_test(:list, :"index!") { routes.draw { get "list" => 'anonymous#list' } }
      end

      context ":defaults, :index! => [:index, :list]" do

        controller(TestRailsApp::DefaultTestController) do
          crud_actions :defaults, :index! => [:index, :list]
          default_action_types.each { |a| test(a) { a } }
          def list
          end
        end

        it "falls back to :all if action is undeclared" do
          routes.draw { get "unknown" => 'anonymous#unknown' }
          # lambda { get :unknown }.should raise_error(NameError)
          crud_test!(:unknown, 0)
        end

        default_actions.each do |a|
          crud_test(a, :"#{a}!")
        end
        crud_test(:list, :"index!") { routes.draw { get "list" => 'anonymous#list' } }
      end

      context ":index => :index!" do

        it "contoller raises" do
          lambda do Class.new(TestRailsApp::DefaultTestController) do
              crud_actions :index => :index!
            end
          end.should raise_error(::StateMethods::CannotOverrideError, "index!")
        end
      end

    end

    context "crud method 'test' set on all crud R and index but not on show" do
      controller(TestRailsApp::DefaultTestController) do
        crud_actions :defaults
        test(:R) { :R }
        test(:index) { :index }
      end

      it "falls back to :all if action is undeclared" do
        routes.draw { get "unknown" => 'anonymous#unknown' }
        # lambda { get :unknown }.should raise_error(NameError)
        crud_test!(:unknown, 0)
      end

      crud_test(:show, :R)
      crud_test(:index, :index)
    end

    context "crud method 'test' passes args correctly" do
      controller(TestRailsApp::DefaultTestController) do
        crud_actions :defaults
        test(:index) { |a, *args| [a, *args] }
      end

      crud_test(:show, Error.new(ArgumentError, "wrong number of arguments (1 for 0)"), :test, 0)
      crud_test(:show, 0, :test)
      crud_test(:index, [0, 1], :test, 0, 1)
      crud_test(:index, [0], :test, 0)
      crud_test(:index, Error.new(ArgumentError, "wrong number of arguments (0 for 1)"), :test)
    end

    context "crud method executes in controller instance scope" do
      default = Class.new(TestRailsApp::DefaultTestController) do
        crud_actions :defaults
        crud_method :test1
        crud_method :test2
        test1(:all) { undefined_method1 }
        test2(:all) { undefined_method2 }
      end

      controller(default) do
        def undefined_method2
          'defined'
        end
      end

      crud_test(:show, Error.new(NameError), :test1)
      crud_test(:show, 'defined', :test2)
    end

    context "crud method delegates to inherited specific state even if superstate is defined in subclass" do
      default = Class.new(TestRailsApp::DefaultTestController) do
        crud_actions :defaults
        test(:index) { 'superclass index' }
      end

      controller(default) do
        test(:R) { 'subclass R' }
      end

      crud_test(:index, 'superclass index')
      crud_test(:show, 'subclass R')
    end

  end

end
