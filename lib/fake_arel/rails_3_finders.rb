module Rails3Finders

  def self.included(base)
    base.class_eval do

      def scope(name, options = {}, &block)
        p "Calling scope"
        named_scope(name, options, &block)
      end

      # the default named scopes
      named_scope :offset, lambda {|offset| {:offset => offset}}
      named_scope :limit, lambda {|limit| {:limit => limit}}
      named_scope :includes, lambda { |*includes| { :include => includes } }
      named_scope :select, lambda {|select| {:select => select } }
      named_scope :order, lambda {|order| {:order => order } }

      __where_fn = lambda do |*where|
        if where.is_a?(Array) and where.size == 1
          {:conditions => where.first}
        else
          {:conditions => where}
        end
      end

      named_scope :where, __where_fn
    end
  end
end

