module ActiveRecord
  module Calculations #:nodoc:
    module ClassMethods
			#fix calculations to consider scopes
			def calculate_with_fakearel(operation, column_name, options = {})
				with_scope(:find => options) do
					options = current_scoped_methods[:find]
					calculate_without_fakearel(operation, column_name, options)
				end
			end
			
			alias_method_chain :calculate, :fakearel
		end
  end
end
