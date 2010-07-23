class Reply < ActiveRecord::Base
  belongs_to :topic, :include => [:replies]

  named_scope :recent, where('replies.created_at > ?', 15.minutes.ago)

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
