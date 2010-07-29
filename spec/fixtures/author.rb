class Author < ActiveRecord::Base
  has_many :topics

  named_scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']
  
  named_scope :with_replies_starting_with, lambda { |text|
    { :conditions => "replies.content LIKE '#{text}%' ", :include  => :replies }
  }
end
