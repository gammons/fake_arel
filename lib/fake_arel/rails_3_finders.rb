module Rails3Finders

  def self.included(base)
    base.class_eval do

      # the default named scopes
      named_scope :offset, lambda {|offset| {:offset => offset}}
      named_scope :limit, lambda {|limit| {:limit => limit}}
      named_scope :includes, lambda { |*includes| { :include => includes }}
      named_scope :order, lambda {|*order| {:order => order.flatten.join(',') }}
      named_scope :joins, lambda {|*join| {:joins => join } if join[0]}
      named_scope :from, lambda {|*from| {:from => from.flatten.join(',') }}
      named_scope :having, lambda {|*having| {:having => having }}
      named_scope :group, lambda {|*group| {:group => group.flatten.join(',') }}
      named_scope :readonly, lambda {|readonly| {:readonly => readonly }}
      named_scope :lock, lambda {|*lock| lock = [true] if lock.empty?; {:lock => lock.first }}

      def self.select(value = Proc.new)
        if block_given?
          all.select {|*block_args| value.call(*block_args) }
        else
          self.scoped(:select => Array.wrap(value).join(','))
        end
      end

      __where_fn = lambda do |*where|
        if where.is_a?(Array) and where.size == 1
          {:conditions => where.first}
        else
          {:conditions => where}
        end
      end

      named_scope :where, __where_fn

      __or_fn = lambda do |*scopes|
        where = []
        joins = []
        includes = []

        # for some reason, flatten is actually executing the scope
        scopes = scopes[0] if scopes.size == 1
        scopes.each do |s|
          scope = s.proxy_scope
          s = s.proxy_options
          begin
            where << scope.merge_conditions(s[:conditions])
          rescue NoMethodError
            # I am ActiveRecord::Base. Only my subclasses define merge_conditions:
            where << subclasses.first.merge_conditions(s[:conditions])
          end
          #where << merge_conditions(s[:conditions])
          joins << s[:joins] unless s[:joins].nil?
          includes << s[:include] unless s[:include].nil?
        end
        scoped = self
        scoped = scoped.includes(includes.uniq.flatten) unless includes.blank?
        scoped = scoped.joins(joins.uniq.flatten) unless joins.blank?
        scoped.where(where.join(" OR "))
      end
      named_scope :or, __or_fn

      # returns a new scope, having removed the options mentioned
      # does *not* support extended scopes
      def self.except(*options)
        # include is renamed to includes in Rails 3
        includes = options.delete(:includes)
        options << :include if includes
  
        new_options = (scope(:find) || {}).reject { |k, v| options.include?(k) }
        with_exclusive_scope(:find => new_options) { scoped }
      end
  
      # returns a new scope, with just the order replaced
      # does *not* support extended scopes
      def self.reorder(*order)
        new_options = (scope(:find) || {}).dup
        new_options[:order] = order.flatten.join(',')
        with_exclusive_scope(:find =>new_options) { scoped }
      end
    
      def self.pluck(column)
        new_options = (scope(:find) || {}).dup
        new_options[:select] = "#{quoted_table_name}.#{column}"
        new_options.delete(:include)
        with_exclusive_scope(:find => new_options) { all.map(&column) }
      end

      def self.fakearel_find_each(options = {:batch_size => 1000}, &block)
        count = self.scoped({}).count
        offset = 0
        while offset < count
          self.scoped(:limit => options[:batch_size], :offset => offset).each { |entry| yield entry }
          offset += options[:batch_size]
        end
      end

      def self.fakearel_destroy
        self.destroy_all(:id => self.scoped({}).select(:id).map(&:id))
      end

      # allow defining scopes Rails 3 style (scope, not named_scope)
      # scope is still a Rails 2 method, so we have to call the correct method
      # depending on the argument types
      def self.scope_with_named_scope(*args, &block)
        if args.length == 2
          case args[1]
            when String, Symbol
              scope_without_named_scope(*args)
            else
              named_scope *args, &block
          end
        else
          scope_without_named_scope(*args)
        end
      end
      class << self
        alias_method_chain :scope, :named_scope
      end
    end
  end
end

