module WithScopeReplacement
  def self.included(base)
    base.class_eval do
      class << self
        def to_sql
          construct_finder_sql self.current_scoped_methods[:find]
        end
        
        alias with_scope_without_arel with_scope
        def with_scope(method_scoping = {}, action = :merge, &block)
          method_scoping = {:find => method_scoping.proxy_options} if method_scoping.class == ActiveRecord::NamedScope::Scope
          with_scope_without_arel( method_scoping, action, &block)
        end
      end
    end
  end
end
