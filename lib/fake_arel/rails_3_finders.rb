module Rails3Finders

  def self.included(base)
    base.class_eval do

      # the default named scopes
      named_scope :offset, lambda {|offset| {:offset => offset}}
      named_scope :limit, lambda {|limit| {:limit => limit}}
      named_scope :includes, lambda { |*includes| { :include => includes }}
      named_scope :select, lambda {|*select| {:select => select.join(',') }}
      named_scope :order, lambda {|*order| {:order => order.join(',') }}
      named_scope :joins, lambda {|*join| {:joins => join } if joins[0]}
      named_scope :from, lambda {|*from| {:from => from }}
      named_scope :having, lambda {|*having| {:having => having }}
      named_scope :group, lambda {|*group| {:group => group }}
      named_scope :readonly, lambda {|readonly| {:readonly => readonly }}
      named_scope :lock, lambda {|lock| {:lock => lock }}

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

