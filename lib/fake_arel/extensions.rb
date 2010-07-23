module ActiveRecord
  module NamedScope
    module ClassMethods
      def named_scope_ext(name, options = {}, &block)
        name = name.to_sym

        scopes[name] = lambda do |parent_scope, *args|
          Scope.new(parent_scope, case options
            when Hash
              options
            when Scope
              options.proxy_options
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

      alias_method :named_scope, :named_scope_ext
    end
  end
end

module NamedScopeExtensions
  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def named_scope_ext(name, options = {}, &block)
      p "GDA CALLING SCOPE"
    end
  end
end

