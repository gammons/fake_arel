class Topic < ActiveRecord::Base
  has_many :replies, :dependent => :destroy, :order => 'replies.created_at DESC'
  belongs_to :author

  scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']

  scope :with_replies_starting_with, lambda { |text|
    { :conditions => "replies.content LIKE '#{text}%' ", :include  => :replies }
  }

  scope :mentions_activerecord_with_replies, includes(:replies).mentions_activerecord
  scope :by_title_with_replies, lambda {|title| includes(:replies).where('topics.title like ?', title) }

  scope :join_replies_by_string, joins('inner join replies on topics.id = replies.topic_id')
  scope :join_replies_by_string_and_author, join_replies_by_string.joins(:author)
  scope :join_replies_by_string_and_author_lambda, join_replies_by_string.joins(:author)
  scope :select_only_id, select('id as super_duper_id').includes(:replies)
  scope :first_four_sorted_by_date, order('id ASC').order('created_at DESC').limit(4)
end
