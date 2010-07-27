module WithScopeReplacement
  def self.included(base)
    base.class_eval do
      class << self
        def to_sql
          construct_finder_sql self.current_scoped_methods[:find]
        end

        def with_scope(method_scoping = {}, action = :merge, &block)
          method_scoping = {:find => method_scoping.proxy_options} if method_scoping.class == ActiveRecord::NamedScope::Scope
          method_scoping = method_scoping.method_scoping if method_scoping.respond_to?(:method_scoping)

          # Dup first and second level of hash (method and params).
          method_scoping = method_scoping.inject({}) do |hash, (method, params)|
            hash[method] = (params == true) ? params : params.dup
            hash
          end

          method_scoping.assert_valid_keys([ :find, :create ])

          if f = method_scoping[:find]
            f.assert_valid_keys(VALID_FIND_OPTIONS)
            set_readonly_option! f
          end

          # Merge scopings
          if [:merge, :reverse_merge].include?(action) && current_scoped_methods
            method_scoping = current_scoped_methods.inject(method_scoping) do |hash, (method, params)|
              case hash[method]
                when Hash
                  if method == :find
                    (hash[method].keys + params.keys).uniq.each do |key|
                      merge = hash[method][key] && params[key] # merge if both scopes have the same key
                      if key == :conditions && merge
                        if params[key].is_a?(Hash) && hash[method][key].is_a?(Hash)
                          hash[method][key] = merge_conditions(hash[method][key].deep_merge(params[key]))
                        else
                          hash[method][key] = merge_conditions(params[key], hash[method][key])
                        end
                      elsif key == :include && merge
                        hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                      elsif key == :joins && merge
                        hash[method][key] = merge_joins(params[key], hash[method][key])
                      else
                        hash[method][key] = hash[method][key] || params[key]
                      end
                    end
                  else
                    if action == :reverse_merge
                      hash[method] = hash[method].merge(params)
                    else
                      hash[method] = params.merge(hash[method])
                    end
                  end
                else
                  hash[method] = params
              end
              hash
            end
          end

          self.scoped_methods << method_scoping
          begin
            yield
          ensure
            self.scoped_methods.pop
          end
        end

        # Works like with_scope, but discards any nested properties.
        def with_exclusive_scope(method_scoping = {}, &block)
          with_scope(method_scoping, :overwrite, &block)
        end

      end
    end
  end
end
