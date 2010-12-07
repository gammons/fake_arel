module ActiveRecord
  module Calculations #:nodoc:
    module ClassMethods
      #fix calculations to consider scoped :group
      def calculate_with_fakearel(operation, column_name, options = {})
        if !options[:group] && (cur_scope = scope(:find)) && cur_scope[:group]
          options = options.dup.merge(:group => cur_scope[:group])
        end
        calculate_without_fakearel(operation, column_name, options)
      end
      
      alias_method_chain :calculate, :fakearel
    end
  end
end
