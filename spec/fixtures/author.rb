class Author < ActiveRecord::Base
  has_many :topics

  scope :mentions_activerecord, :conditions => ['topics.title LIKE ?', '%ActiveRecord%']
  
  scope :with_replies_starting_with, lambda { |text|
    { :conditions => "replies.content LIKE '#{text}%' ", :include  => :replies }
  }
end
