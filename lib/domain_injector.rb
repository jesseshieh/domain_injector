require "domain_injector/version"
require 'memoist'

module DomainInjector
  # Bunch of scary ruby meta-programming in here.
  #
  # The Injector instantiates objects for you and injects their dependencies for you.
  # It does this by looking at the name of your constructor parameters and matching them with
  # the injector's node names. Nodes are objects in your object-graph. For example,
  # if you have a node named :foo which maps to the number 1, and you ask the injector to
  # instantiate Bar with a parameter named foo, it will give you an instance of Bar with 1
  # injected automatically as the parameter foo.
  #
  # Simple Example
  #
  # class Bar
  #   def initialize(foo)
  #     p foo
  #   end
  # end
  # injector = DomainInjector::Injector.new(
  #   internal_nodes: { bar: Bar },
  #   leaf_nodes: { foo: ->{1} }
  # )
  # p injector.node(:bar)
  #
  # It does the instantiation and injection recursively through your entire object graph.
  # For example, if you have an object M that depends on A, I, H, e:
  #
  # class H
  #   def initialize
  #     p 'creating H'
  #   end
  # end
  #
  # class I
  #   def initialize(h:)
  #     p 'creating I'
  #   end
  # end
  #
  # class A
  #   def initialize(i:, h:)
  #     p 'creating A'
  #   end
  # end
  #
  # class M
  #   def initialize(a, h, b=3, *c, d: 4, e:, **f, &g)
  #     p 'creating M'
  #   end
  # end
  #
  # injector = DomainInjector::Injector.new(
  #   internal_nodes: { a: A, i: I, h: H, m: M },
  #   leaf_nodes: { e: ->{5} }
  # )
  # p injector.node(:m)
  #
  # Produces output:
  # "creating H"
  # "creating I"
  # "creating A"
  # "creating M"
  # #<M:0x007fb7037a3908>
  class Injector
    class NodeNotFound < Exception; end
    class CanNotCreate < Exception; end

    extend Memoist

    # - internal_nodes are classes that will be automatically instantiated with parameters
    # automatically injected. They can also be injected into other nodes once instantiated.
    # - leaf_nodes will be injected into other nodes as-is.
    # - No cyclical dependencies allowed. You must resolve the cyclical dependency outside of the
    # Injector.
    def initialize(internal_nodes:, leaf_nodes:)
      intersecting_keys = Set.new(internal_nodes.keys).intersection(Set.new(leaf_nodes.keys))
      fail "Duplicate keys: #{intersecting_keys.to_a}" unless intersecting_keys.empty?
      @internal_nodes = internal_nodes
      @leaf_nodes = leaf_nodes
    end

    def valid_node_names
      @internal_nodes.keys + @leaf_nodes.keys
    end
    memoize :valid_node_names

    # Convenience methods.
    # injector.foo instead of injector.node(:foo)
    def method_missing(method_sym, *arguments, &block)
      if valid_node_names.include? method_sym
        node(method_sym)
      else
        super
      end
    end

    # Always define respond_to_missing? when overriding method_missing.
    # https://robots.thoughtbot.com/always-define-respond-to-missing-when-overriding
    def respond_to_missing?(method_sym, include_private = false)
      valid_node_names.include?(method_sym) || super
    end

    # Provides an argument that can be injected. Constructs a node in the object-tree along with
    # all it's dependencies.
    def node(name)
      leaf_node = @leaf_nodes.fetch(name, nil)
      return leaf_node.call unless leaf_node.nil?

      internal_node = @internal_nodes.fetch(name, nil)
      if internal_node.nil?
        fail NodeNotFound, "Node #{name} not found. Did you forget to add #{name} to the injector?"
      end

      begin
        create(internal_node)
      rescue NodeNotFound, CanNotCreate => e
        # Chain the messages together so there is a trace.
        raise CanNotCreate, "#{e.message}\nCould not create node #{name}."
      end
    end
    memoize :node

    # Instantiates `node` with injected parameters.
    def create(node)
      reqs = required_positional_params(node.instance_method(:initialize))
      keyreqs = required_keyword_params(node.instance_method(:initialize))
      if keyreqs.empty?
        node.new(*reqs)
      else
        node.new(*reqs, **keyreqs)
      end
    end

    # Calls `method` with injected parameters
    def call(method)
      # We don't support optional arguments, splats, or blocks yet.
      # For a method like this one: def m(b=3,*c,d: 4, **f,&g)
      # This method will result in
      # b = 3
      # c = []
      # d = 4
      # f = {}
      # g = nil
      reqs = required_positional_params(method)
      keyreqs = required_keyword_params(method)
      if keyreqs.empty?
        method.call(*reqs)
      else
        method.call(*reqs, **keyreqs)
      end
    end

    # Provides a list of required keyword arguments which can be injected into `method`.
    def required_keyword_params(method)
      method.parameters.select do |type, name|
        type == :keyreq
      end.map do |type, name|
        { name => node(name) }
      end.inject({}, &:merge)
    end

    # Provides a list of required positional arguments which can be injected into `method`.
    def required_positional_params(method)
      # From: https://www.ruby-forum.com/topic/4416563
      # def m(a,b=3,*c,d: 4,e:, **f,&g)
      # end
      #
      # method(:m).parameters
      # #=> [[:req, :a], [:opt, :b], [:rest, :c], [:keyreq, :e], [:key, :d],
      # [:keyrest, :f], [:block, :g]]
      #
      # puts method(:m).parameters.map(&:first)
      #
      # #=>
      # req     # required argument
      # opt     # optional argument
      # rest    # rest of arguments as array
      # keyreq  # reguired key argument (2.1+)
      # key     # key argument
      # keyrest # rest of key arguments as Hash
      # block   # block parameter
      method.parameters.select do |type, name|
        type == :req
      end.map do |type, name|
        node(name)
      end
    end
  end
end
