module ActiveRecord
  module NamedScope
    module ClassMethods
      def named_scope(name, options = {}, &block)
        name = name.to_sym

        scopes[name] = lambda do |parent_scope, *args|
          Scope.new(parent_scope, case options
            when Hash
              options
            when Scope
              # unspin the scope and generate a hash
              local_scope = options.proxy_scope
              ret = options.proxy_options
              while local_scope.class == ActiveRecord::NamedScope::Scope
                ret[:conditions] = merge_conditions(ret[:conditions], local_scope.proxy_options[:conditions])
                ret[:includes] = merge_includes(ret[:includes], local_scope.proxy_options[:includes]) if ret[:includes] or local_scope.proxy_options[:includes]
                ret[:joins] = merge_includes(ret[:joins], local_scope.proxy_options[:joins])
                local_scope = local_scope.proxy_scope
              end
              ret
            when Proc
              if self.model_name != parent_scope.model_name
                options.bind(parent_scope).call(*args)
              else
                options.call(*args)
              end
          end, &block)
        end

        singleton_class.send :define_method, name do |*args|
          scopes[name].call(self, *args)
        end
      end
    end

    class Scope
      attr_reader :proxy_scope, :proxy_options, :current_scoped_methods_when_defined
      undef select
      [].methods.each do |m|
        unless m =~ /^__/ || (NON_DELEGATE_METHODS + ['select']).include?(m.to_s)
          delegate m, :to => :proxy_found
        end
      end

      delegate :scopes, :with_scope, :scoped_methods, :to => :proxy_scope

      def initialize(proxy_scope, options = {}, &block)
        options ||= {}
        options = options.proxy_options if options.class == ActiveRecord::NamedScope::Scope
        [options[:extend]].flatten.each { |extension| extend extension } if options[:extend]
        extend Module.new(&block) if block_given?
        unless Scope === proxy_scope
          @current_scoped_methods_when_defined = proxy_scope.send(:current_scoped_methods)
        end
        @proxy_scope, @proxy_options = proxy_scope, options.except(:extend)
      end

      def reload
        load_found; self
      end

      def first(*args)
        if args.first.kind_of?(Integer) || (@found && !args.first.kind_of?(Hash))
          proxy_found.first(*args)
        else
          find(:first, *args)
        end
      end

      def last(*args)
        if args.first.kind_of?(Integer) || (@found && !args.first.kind_of?(Hash))
          proxy_found.last(*args)
        else
          find(:last, *args)
        end
      end

      def size
        @found ? @found.length : count
      end

      def empty?
        @found ? @found.empty? : count.zero?
      end

      def respond_to?(method, include_private = false)
        super || @proxy_scope.respond_to?(method, include_private)
      end

      def any?
        if block_given?
          proxy_found.any? { |*block_args| yield(*block_args) }
        else
          !empty?
        end
      end

      protected
      def proxy_found
        @found || load_found
      end

      private
      def method_missing(method, *args, &block)
        if scopes.include?(method)
          scopes[method].call(self, *args)
        else
          with_scope({:find => proxy_options, :create => proxy_options[:conditions].is_a?(Hash) ?  proxy_options[:conditions] : {}}, :reverse_merge) do
            method = :new if method == :build
            if current_scoped_methods_when_defined && !scoped_methods.include?(current_scoped_methods_when_defined)
              with_scope current_scoped_methods_when_defined do
                proxy_scope.send(method, *args, &block)
              end
            else
              proxy_scope.send(method, *args, &block)
            end
          end
        end
      end

      def load_found
        @found = find(:all)
      end
    end

  end
end
