class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :author

  named_scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']

  named_scope :with_replies_starting_with, lambda { |text|
    { :conditions => "replies.content LIKE '#{text}%' ", :include  => :replies }
  }

  named_scope :mentions_activerecord_with_replies, includes(:replies).mentions_activerecord
  named_scope :by_title_with_replies, lambda {|title| includes(:replies).where('topics.title like ?', title) }

  named_scope :join_replies_by_string, joins('inner join replies on topics.id = replies.topic_id')
  named_scope :join_replies_by_string_and_author, join_replies_by_string.joins(:author)
  named_scope :join_replies_by_string_and_author_lambda, join_replies_by_string.joins(:author)
  named_scope :select_only_id, select('id as super_duper_id').includes(:replies)
  named_scope :first_four_sorted_by_date, order('id ASC').order('created_at DESC').limit(4)
end
