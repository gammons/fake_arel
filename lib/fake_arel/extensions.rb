module ActiveRecord
  module NamedScope
    module ClassMethods
      def named_scope(name, options = {}, &block)
        name = name.to_sym

        scopes[name] = lambda do |parent_scope, *args|
          Scope.new(parent_scope, case options
            when Hash, Scope
              options
            when Proc
              options.call(*args)
          end, &block)
        end

        singleton_class.send :define_method, name do |*args|
          scopes[name].call(self, *args)
        end
      end
    end

    class Scope
      undef select

      alias initialize_without_arel initialize
      def initialize(proxy_scope, options = {}, &block)
        options = options.unspin if options.class == ActiveRecord::NamedScope::Scope
        initialize_without_arel(proxy_scope, options, &block)
      end

      def unspin
        # unspin the scope and generate a hash
        local_scope = proxy_scope
        ret = proxy_options
        while local_scope.class == ActiveRecord::NamedScope::Scope
          local_conditions = merge_conditions(local_scope.proxy_options[:conditions])
          if local_conditions && ret[:conditions]
            if !ret[:conditions].index(local_conditions)
              ret[:conditions] = merge_conditions(ret[:conditions], local_scope.proxy_options[:conditions])
            end
          elsif local_conditions
            ret[:conditions] = local_conditions
          end
          ret[:includes] = merge_includes(ret[:includes], local_scope.proxy_options[:includes]) if ret[:includes] || local_scope.proxy_options[:includes]
          ret[:joins] = merge_includes(ret[:joins], local_scope.proxy_options[:joins])
          ret[:order] = [local_scope.proxy_options[:order], ret[:order]].select{|o| !o.blank?}.join(',') if ret[:order] || local_scope.proxy_options[:order]
          local_scope = local_scope.proxy_scope
        end
        ret
      end
    end

  end
end
