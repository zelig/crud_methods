# CrudeMethods

This is a rails support library that provides a way to define 
action-dependent controller methods in an order-independent declarative way. The action types default to rails CRUD actions and can be extended or modified on each controller. 

This gem is supposed to be used by restful/resourceful controller abstractions as a simple and flexible interface for the user to set potentially action-specific behavour.

Here I give some end-user cases. Note that this gem does not provide the particular controller abstraction functionalities in the examples, just demonstrate a common use of this specification pattern.

1. a resourceful controller scaffold but adding a search action. The user just hooks into the resource retrieval scope chain, otherwise all behave as a crud index-type action:
 
```ruby
class ModelsController
  include ResourfulCrudActions
  crud_actions :defaults, :index! => [:search]
  resources :search do |scope|
    scope.search(params[:search])
  end
end
```

2. Imagine a responder abstraction, then the user can modify action-specific behaviour.

```ruby
class ModelsController
  include SmartResponder
  crud_actions :defaults
  response_on_success :create do |format|
    format.html { redirect_to home_path } 
  end
end
```

How these would use `crud_methods` is described in 'Usage' section.

## Features

A crud method allows
- class-level declaration of action specific behaviour
- the method definition block is executed in controller instance scope when the method is called on the instantiated controller.
- actions are hierarchically organized allowing default behaviour for an action _type_ (with bang, like `:index!`)
- user added custom actions will fall back to crud type they belong to
- specification on different action-types are order-independent say action is `:show`, if current controller specifies a fallback with `:all`, but a specification for `:show!` is inherited, then the latter wins.
- for a more thorough understanding, see the [documentation of the `state_methods` gem](https://github.com/zelig/state_methods.git).

## Usage

This section describes how the developer of any controller abstraction gem will use `crud_methods`.

```ruby
require 'crud_methods'           # require crud_method
module MyGem::Controller
  def self.included(base)
    base.class_eval do
      include CrudMethods         # include crud_method support
      crud_method :resource       # declare action-specific method
      # define your action-specific behaviour here on the class level
      resource :create!, :new! do        
        resource_class.new(params[model_name], :as => current_role)
      end 
      #...
    end
  end
```

Then the user will do:
```ruby
class SignupsController
  include MyGem::Controller
  crud_actions :defaults, :new! => [:wait]
  # instead of signup just put on waiting list
  resource :wait do
    resource_class.new(params[model_name], :as => current_role).
      tap { status = :waiting }
  end
end
```

## Implementation

This gem is basically a paticular use case of the [`state_methods` gem](https://github.com/zelig/state_methods.git) on controller classes where the 'state accessor method' is `action_name` and the default state partition is the usual CRUD actions of rails.

## Gotchas

- do not use `super` within the class-level method definition block. it won't refer to anything reliable. use _fallback_ calls. :TODO: add more info.
- specifying a method for a type (of action), will not override other specs for a subtype (or particular action) either earlier or later. This may be counterintuitive to some especially that  specifications for action types can be 'hidden' coming via controller inheritance or included modules. :TODO: add more info.
- see the [documentation of the `state_methods` gem](https://github.com/zelig/state_methods.git)

## Installation

Add this line to your application's Gemfile:

    gem 'crud_methods'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install crud_methods


## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
