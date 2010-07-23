ActiveRecord::Schema.define do
  create_table "topics", :force => true do |t|
    t.column "project_id", :integer
    t.column "title",      :string
    t.column "subtitle",   :string
    t.column "content",    :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
  end

  create_table "replies", :force => true do |t|
    t.column "content",    :text
    t.column "created_at", :datetime
    t.column "updated_at", :datetime
    t.column "topic_id",   :integer
  end
end
