# Politely lifted from fcheung's selectable_includes plugin for ActiveRecord
# https://github.com/fcheung/selectable_includes/blob/master/lib/selectable_includes.rb
class ActiveRecord::Base
  class << self
    def construct_finder_sql_with_included_associations_with_selectable_includes(options, join_dependency)
      scope = scope(:find)
      select_options = options[:select] || (scope && scope[:select])
      sql = construct_finder_sql_with_included_associations_without_selectable_includes(options, join_dependency)
      unless select_options.blank?
        sql.sub!(/\ASELECT /, "SELECT #{select_options}, ")
      end
      sql
    end
    alias_method_chain :construct_finder_sql_with_included_associations, :selectable_includes
  end
end

class ActiveRecord::Associations::ClassMethods::JoinDependency
  def instantiate_with_selectable_includes(rows)
    unless rows.empty?
      keys_from_select = rows.first.keys.reject {|k| k =~ /\At\d+_r\d+/}
      join_base.extra_columns = keys_from_select
    end
    instantiate_without_selectable_includes(rows)
  end
  alias_method_chain :instantiate, :selectable_includes
end

class ActiveRecord::Associations::ClassMethods::JoinDependency::JoinBase
  attr_accessor :extra_columns

  def extract_record_with_selectable_includes(row)
    record = extract_record_without_selectable_includes(row)
    extra_columns.inject(record){|record, an| record[an] = row[an]; record} if extra_columns
    record
  end

  alias_method_chain :extract_record, :selectable_includes
end

