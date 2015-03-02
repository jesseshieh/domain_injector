require 'spec_helper'

RSpec.describe DomainInjector::Injector do
  it 'constructs the object' do
    class Bar
      def initialize(foo)
        @foo = foo
      end
      attr_reader :foo
    end
    injector = DomainInjector::Injector.new(
      internal_nodes: { bar: Bar },
      leaf_nodes: { foo: -> { 1 } }
    )
    result = injector.node(:bar)
    expect(result).to be_an_instance_of(Bar)
    expect(result.foo).to be 1
  end

  context 'with several layers of dependencies' do
    context 'with several kinds of parameters' do
      it 'constructs the object' do
        class H
          def initialize
          end
        end

        class I
          def initialize(h:)
            @h = h
          end
          attr_reader :h
        end

        class A
          def initialize(i:, h:)
            @i = i
            @h = h
          end
          attr_reader :i
          attr_reader :h
        end

        class M
          def initialize(a, h, b = 3, *c, d: 4, e:, **f, &g)
            @a = a
            @b = b
            @c = c
            @d = d
            @e = e
            @f = f
            @g = g
            @h = h
          end
          attr_reader :a
          attr_reader :b
          attr_reader :c
          attr_reader :d
          attr_reader :e
          attr_reader :f
          attr_reader :g
          attr_reader :h
        end

        injector = DomainInjector::Injector.new(
          internal_nodes: { a: A, i: I, h: H, m: M },
          leaf_nodes: { e: -> { 5 } }
        )
        result = injector.node(:m)
        expect(result).to be_an_instance_of(M)
        expect(result.a).to be_an_instance_of(A)
        expect(result.b).to eq 3
        expect(result.c).to eq []
        expect(result.d).to eq 4
        expect(result.e).to eq 5
        expect(result.f).to eq({})
        expect(result.g).to eq nil
        expect(result.h).to be_an_instance_of(H)

        expect(result.a.i).to be_an_instance_of(I)
        expect(result.a.h).to be_an_instance_of(H)

        expect(result.a.i.h).to be_an_instance_of(H)
      end
    end
  end
end
