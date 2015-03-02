# DomainInjector

The Injector instantiates objects for you and injects their dependencies for you.
It does this by looking at the name of your constructor parameters and matching them with
the injector's node names. Nodes are objects in your object-graph. For example,
if you have a node named :foo which maps to the number 1, and you ask the injector to
instantiate Bar with a parameter named foo, it will give you an instance of Bar with 1
injected automatically as the parameter foo.

Simple Example

    class Bar
     def initialize(foo)
       p foo
     end
    end
    
    injector = DomainInjector::Injector.new(
     internal_nodes: { bar: Bar },
     leaf_nodes: { foo: ->{1} }
    )
    p injector.node(:bar)

It does the instantiation and injection recursively through your entire object graph.
For example, if you have an object M that depends on A, I, H, e:

    class H
     def initialize
       p 'creating H'
     end
    end
    
    class I
     def initialize(h:)
       p 'creating I'
     end
    end
    
    class A
     def initialize(i:, h:)
       p 'creating A'
     end
    end
    
    class M
     def initialize(a, h, b=3, *c, d: 4, e:, **f, &g)
       p 'creating M'
     end
    end
    
    injector = DomainInjector::Injector.new(
     internal_nodes: { a: A, i: I, h: H, m: M },
     leaf_nodes: { e: ->{5} }
    )
    p injector.node(:m)
    
    Produces output:
    "creating H"
    "creating I"
    "creating A"
    "creating M"
    #<M:0x007fb7037a3908>

## Installation

Add this line to your application's Gemfile:

    gem 'domain_injector'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install domain_injector

## Usage

TODO: Write usage instructions here

## Contributing

1. Fork it ( https://github.com/[my-github-username]/domain_injector/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
