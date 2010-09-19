class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :author

  named_scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']
  
  named_scope :with_replies_starting_with, lambda { |text|
    { :conditions => "replies.content LIKE '#{text}%' ", :include  => :replies }
  }
  
  named_scope :join_replies_by_string, joins('inner join replies on topics.id = replies.topic_id')
  named_scope :join_replies_by_string_and_author, join_replies_by_string.joins(:author)
  named_scope :join_replies_by_string_and_author_lambda, join_replies_by_string.joins(:author)
end
