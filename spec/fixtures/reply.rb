class Reply < ActiveRecord::Base
  belongs_to :topic, :include => [:replies]

  named_scope :recent, where('replies.created_at > ?', 15.minutes.ago)
  named_scope :recent_limit_1, where('replies.created_at > ?', 15.minutes.ago).limit(1)
  named_scope :recent_with_content_like_ar, recent.where('lower(content) like ?', "AR%")
  named_scope :recent_with_content_like_ar_and_id_4, recent.where('lower(content) like ?', "AR%").where("id = 4")
  named_scope :recent_joins_topic, recent.joins(:topic)
  named_scope :topic_title_is, lambda {|topic_title| where("topics.title like ?", topic_title + "%") }

  named_scope :arel_id, :conditions => "id = 1"
  named_scope :arel_id_with_lambda, lambda {|aid| arel_id}
  named_scope :arel_id_with_nested_lambda, lambda {|aid| arel_id_with_lambda(aid)}
  
  validates_presence_of :content

  def self.find_all_but_first
    with_scope(where('id > 1')) do
      self.all
    end
  end
end
