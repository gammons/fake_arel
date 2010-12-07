module ActiveRecord
  module Calculations #:nodoc:
    module ClassMethods
      #fix calculations to consider scoped :group
      def calculate_with_fakearel(operation, column_name, options = {})
        cur_scope = scope(:find)
        if !options[:group] && cur_scope && cur_scope[:group]
          options = options.reverse_merge(cur_scope.slice(:group, :having))
        end
        calculate_without_fakearel(operation, column_name, options)
      end
      
      alias_method_chain :calculate, :fakearel
    end
  end
end
