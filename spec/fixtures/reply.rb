class Reply < ActiveRecord::Base
  attr_accessor :before_destroy_called, :after_destroy_called

  belongs_to :topic, :include => [:replies]

  scope :recent, where('replies.created_at > ?', 15.minutes.ago.utc.to_s(:db))
  scope :recent_two_wheres, where('replies.created_at > ?', 15.minutes.ago.utc.to_s(:db)).where(:id => 5)
  scope :recent_limit_1, where('replies.created_at > ?', 15.minutes.ago.utc.to_s(:db)).limit(1)
  scope :recent_with_content_like_ar, recent.where('lower(replies.content) like ?', "AR%")
  scope :recent_with_content_like_ar_and_id_4, recent.where('lower(replies.content) like ?', "AR%").where("id = 4")
  scope :recent_joins_topic, recent.joins(:topic)
  scope :topic_title_is, lambda {|topic_title| joins(:topic).where("topics.title like ?", topic_title + "%") }

  scope :join_topic_and_author, joins(:topic => [:author])
  scope :filter_join_topic_and_author, joins(:topic => [:author]).where('lower(replies.content) like ?','AR%')

  scope :arel_id, :conditions => "id = 1"
  scope :arel_id_with_lambda, lambda {|aid| arel_id}
  scope :arel_id_with_nested_lambda, lambda {|aid| arel_id_with_lambda(aid)}

  scope :id_asc, order('id asc')
  scope :id_desc, order('id desc')
  scope :topic_4_id_asc, id_asc.where(:topic_id => 4)
  scope :topic_4_id_desc, id_desc.where(:topic_id => 4)
  scope :topic_id, lambda{|topic_id| where(:topic_id => topic_id)}
  scope :recent_topic_id, lambda{|topic_id| recent.where(:topic_id => topic_id)}
  scope :topic__id_asc, lambda{|topic_id| id_asc.where(:topic_id => topic_id)}
  scope :topic__id_desc, lambda{|topic_id| id_desc.where(:topic_id => topic_id)}
  scope :topic__id_desc1, lambda{|topic_id| where(:topic_id => topic_id).id_desc}
  scope :topic__id_desc2, lambda{|topic_id| order('id desc').where(:topic_id => topic_id)}
  scope :topic__id_desc3, lambda{|topic_id| where(:topic_id => topic_id).order('id desc')}
  scope :topic_id_asc, order('topic_id asc')
  scope :topic_id_asc_id_desc, order('topic_id asc').id_desc
  scope :lam_topic_id_asc_id_desc, lambda{ topic_id_asc.id_desc }

  validates_presence_of :content

  def self.find_all_but_first
    with_scope(where('id > 1')) do
      self.all
    end
  end

  def before_destroy
    $before_destroy_called = true
  end

  def after_destroy
    $after_destroy_called = true
  end
end
