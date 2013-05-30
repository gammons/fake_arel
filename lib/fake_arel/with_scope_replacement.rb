module WithScopeReplacement
  def self.included(base)
    base.class_eval do
      class << self
        def to_sql
          jd = JoinDependency.new(self, merge_includes(scope(:find, :include), nil), nil)
          construct_finder_sql_with_included_associations(current_scoped_methods, jd)
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
                      elsif key == :select && merge
                        hash[method][key] = merge_includes(hash[method][key], params[key]).uniq.join(', ')
                      elsif key == :include && merge
                        hash[method][key] = merge_includes(hash[method][key], params[key]).uniq
                      elsif key == :joins && merge
                        hash[method][key] = merge_joins(params[key], hash[method][key])
                      # see https://rails.lighthouseapp.com/projects/8994/tickets/2810-with_scope-should-accept-and-use-order-option
                      # it works now in reverse order to comply with ActiveRecord 3
                      elsif key == :order && merge && !default_scoping.any?{ |s| s[method].keys.include?(key) }
                        hash[method][key] = [hash[method][key], params[key]].select{|o| !o.blank?}.join(', ')
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
      end
    end
  end
end
