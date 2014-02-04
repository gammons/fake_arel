require 'spec_helper'
require 'reply'
require 'topic'
require 'author'

describe "Fake Arel" do
  it "should accomplish basic where" do
    Reply.where(:id => 1).first.id.should == 1
    Reply.where("id = 1").first.id.should == 1
    Reply.where("id = ?", 1).first.id.should == 1

    Reply.recent.size.should == 1
    Reply.recent_limit_1.all.size.should == 1
  end

  it "should be able to use where and other named scopes within named scopes" do
    Reply.arel_id.size.should == 1
    Reply.arel_id.first.id.should == 1
  end

  it "should be able to use where and other named scopes within a lambda" do
    Reply.arel_id_with_lambda(1).size.should == 1
    Reply.arel_id_with_lambda(1).first.id.should == 1
  end

  it "should be able to use where and other named scopes within a nested lambda" do
    Reply.arel_id_with_nested_lambda(1).size.should == 1
    Reply.arel_id_with_nested_lambda(1).first.id.should == 1
  end

  it "should be all chainable" do
    replies = Reply.select("content,id").where("id > 1").order("id desc").limit(1)
    replies.all.size.should == 1
  end

  it "should work with scope and with exclusive scope" do
    Reply.find_all_but_first.map(&:id).should == [2,3,4,5,6]
  end

  describe ".to_sql" do
    it "should be able to output sql" do
      sql = Topic.select('content').joins(:replies).limit(1).order('id desc').where(:author_id => 1).to_sql
      sql.should =~ /SELECT content/i
      sql.should =~ /JOIN "replies"/i
      sql.should =~ /"author_id" = 1/
      sql.should =~ /LIMIT 1/i
      sql.should =~ /ORDER BY id desc/i
      sql = Reply.topic_4_id_desc.to_sql
      sql.should =~ /"topic_id" = 4/
      sql.should =~ /ORDER BY id desc/i
    end

    it "should includes includes when including included includes" do
      sql = Topic.includes(:replies).includes(:author).where("replies.id = 1").to_sql
      sql.should =~ /JOIN "replies"/i
      sql.should =~ /JOIN "authors"/i
    end

    it "should only include the selects we select" do
     sql = Topic.select("topics.id").includes(:replies).where("replies.id = 1").to_sql
     sql.should =~ /FROM "topics"/
     sql.should =~ /SELECT topics.id/
    end
  end

  it "should generate same sql always" do
    first_sql = Topic.first_four_sorted_by_date.to_sql
    second_sql = Topic.first_four_sorted_by_date.to_sql
    first_sql.should == second_sql
  end
  it "should not dublication conditions" do
    sql = Topic.select('content').joins(:replies).limit(1).order('id desc').where(:author_id => 1).to_sql
    sql.should_not =~ /"author_id" = 1.+"author_id" = 1/
  end

  it "should be able to chain named scopes within a named_scope" do
    Reply.recent_with_content_like_ar.should == Reply.find(:all, :conditions => "id = 5")
    Reply.recent_with_content_like_ar_and_id_4.should == []
    Reply.recent_joins_topic.topic_title_is("ActiveRecord").first.should == Reply.find(5)
    Reply.recent_joins_topic.topic_title_is("Nothin").first.should == nil
  end

  it "should be able to join multiple items" do
    Reply.filter_join_topic_and_author.all.should == Reply.find(:all, :conditions => "id in (5,6)")
    Reply.filter_join_topic_and_author.recent_with_content_like_ar.all.should == Reply.find(:all, :conditions => "id = 5")
  end

  it "should be able to take a select after a where" do
    replies = Reply.where("id = 5").select(:id).all
    replies.size.should == 1
    replies[0].attributes.should == {"id" => 5}
  end

  it "should be able to group properly" do
    Reply.group(:topic_id).map(&:topic_id).sort.should == [1, 2, 4].sort
  end

  it "should support pluck" do
    Reply.where(:id => 5).pluck(:id).should == [5]
  end

  it "should support reorder" do
    Reply.where(:id => [4, 5]).order("id DESC").reorder("id").pluck(:id).should == [4, 5]
  end

  it "should support except" do
    Reply.select(:id).except(:select).first.created_at.should_not == nil
  end

  it "should properly chain order scope in definitions" do
    Reply.topic_4_id_asc.all.should == Reply.find(:all, :conditions => {:topic_id => 4}, :order=>'id asc')
    Reply.topic_4_id_desc.all.should == Reply.find(:all, :conditions => {:topic_id => 4}, :order=>'id desc')
  end

  it "should properly chain scope in definitions by lambda" do
    Reply.recent_topic_id(4).all.should == Reply.find_all_by_id(5)
  end

  it "should properly chain order scope in definitions by lambda" do
    Reply.topic__id_asc(4).all.should == Reply.find(:all, :conditions => {:topic_id => 4}, :order=>'id asc')
    Reply.order('id desc').topic_id(4).all.should == Reply.find(:all, :conditions => {:topic_id => 4}, :order=>'id desc')
    topic_4_id_desc = Reply.find(:all, :conditions => {:topic_id => 4}, :order=>'id desc')
    Reply.topic__id_desc(4).all.should == topic_4_id_desc
    Reply.topic__id_desc1(4).all.should == topic_4_id_desc
    Reply.topic__id_desc2(4).all.should == topic_4_id_desc
    Reply.topic__id_desc3(4).all.should == topic_4_id_desc
  end

  it "should chain order scopes" do
    # see https://rails.lighthouseapp.com/projects/8994/tickets/2810-with_scope-should-accept-and-use-order-option
    # it works now in reverse order to comply with ActiveRecord 3
    Reply.order('topic_id asc').order('created_at desc').all.should == Reply.find(:all, :order=>'topic_id asc, created_at desc')
    Reply.order('topic_id asc').id_desc.all.should == Reply.find(:all, :order=>'topic_id asc, id desc')
    Reply.topic_id_asc.id_desc.all.should == Reply.find(:all, :order=>'topic_id asc, id desc')
    Reply.topic_id_asc_id_desc.all.should == Reply.find(:all, :order=>'topic_id asc, id desc')
    Reply.lam_topic_id_asc_id_desc.all.should == Reply.find(:all, :order=>'topic_id asc, id desc')
    Reply.with_scope(:find=>{:order=>'topic_id asc'}) do
      Reply.with_scope(:find=>{:order=>'created_at desc'}) do
        Reply.all
      end
    end.should == Reply.find(:all, :order=>'created_at desc, topic_id asc')
  end

  it "should chain string join scope" do
    lambda {
      Topic.join_replies_by_string_and_author.all
      Topic.join_replies_by_string_and_author_lambda.all
    }.should_not raise_error
  end

  it "should properly chain with includes" do
    topics = nil
    lambda {
      topics = Topic.mentions_activerecord_with_replies.all
    }.should_not raise_error
    topics.each {|topic|
      topic.replies.loaded?.should be_true
    }
  end

  it "should properly chain with includes in lambda" do
    topics = nil
    lambda {
      topics = Topic.by_title_with_replies('%ActiveRecord%').all
    }.should_not raise_error
    topics.each {|topic|
      topic.replies.loaded?.should be_true
    }
  end

  it "should respond to scoped" do
    Reply.scoped({}).class.should == ActiveRecord::NamedScope::Scope
  end

  # Github issue #8, fake_arel was adding conditions over and over
  # to a names scope.
  it "should not add a billion parens and conditions" do
    pass_1 = Reply.recent.to_sql
    pass_2 = Reply.recent.to_sql
    pass_3 = Reply.recent.to_sql
    pass_1.should == pass_2
    pass_2.should == pass_3

    pass1 = Reply.filter_join_topic_and_author.to_sql
    pass2 = Reply.filter_join_topic_and_author.to_sql
    pass3 = Reply.filter_join_topic_and_author.to_sql
    pass_1.should == pass_2
    pass_2.should == pass_3

    pass1 = Reply.recent_joins_topic.topic_title_is('Nothin').to_sql
    pass2 = Reply.recent_joins_topic.topic_title_is('Nothin').to_sql
    pass3 = Reply.recent_joins_topic.topic_title_is('Nothin').to_sql
    pass_1.should == pass_2
    pass_2.should == pass_3
  end

  it "should be able to combine named scopes with or" do
    q1 = Reply.where(:id => 1)
    q2 = Reply.where(:id => 2)
    q3 = Reply.where(:id => 3)
    q4 = Reply.where(:id => 4)
    Reply.or(q1,q2).all.map(&:id).should == [1,2]
    Reply.or(q1,q2,q3).all.map(&:id).should == [1,2,3]

    # here's something crazy
    or1 = Reply.or(q1,q2)
    or2 = Reply.or(q3,q4)
    Reply.or(or1,or2).all.map(&:id).should == [1,2,3,4]

    # an example using joins, as well as a query that returns nothing
    Reply.or(Reply.recent_joins_topic, Reply.topic_title_is("Nothin")).all.map(&:id).should == [5]
  end

  it 'should be able to combine with "or", an empty named scope with another non-empty one' do
    q1 = Reply.where(:id => 0)
    q2 = Reply.where(:id => 2)
    Reply.or(q1,q2).all.map(&:id).should == [2]
  end

  it 'should be able to combine with "or" a different class' do
    q1 = Author.where(:id => 0)
    q2 = Author.where(:id => 1)
    Author.or(q1,q2).all.map(&:id).should == [1]
  end

  it "should use select like rails 3 uses select" do
    lambda { Reply.all.select {|r| r.id == 1 }}.should_not raise_error
    Reply.all.select {|r| r.id == 1 }.size.should == 1
    Reply.all.select {|r| r.id == 1 }.first.id.should == 1
    lambda { Reply.select(:id).first.content }.should raise_error(ActiveRecord::MissingAttributeError)
  end

  it "should respond to batch_find" do
    10.times {|i| Reply.create(:content => "This is reply number #{i}") }

    count = 0
    entries = []
    Reply.where("content LIKE('This is reply number%')").fakearel_find_each(:batch_size => 5) do |reply|
      count += 1
      reply.class.should == Reply
      entries << reply
    end
    count.should == 10
    entries.should == Reply.where("content LIKE('This is reply number%')")

    entries = []
    Reply.order("id desc").fakearel_find_each(:batch_size => 5) do |reply|
      entries << reply
    end

    entries.map(&:id).each_with_index do |e,i|
      if i < entries.size
        e.should be > e[i+1]
      end
    end

    # test jumping out and not batching
    entries = []
    Reply.order("id desc").fakearel_find_each do |reply|
      entries << reply
    end

    entries.map(&:id).each_with_index do |e,i|
      if i < entries.size
        e.should be > e[i+1]
      end
    end
  end

  describe "fakearel_destroy" do
    it "should destroy within a scope" do
      $before_destroy_called = false
      $after_destroy_called = false
      replies = Reply.where(:id => [1,2])
      replies.fakearel_destroy
      Reply.where(:id => [1,2]).should == []
      Reply.first.id.should == 3
      $before_destroy_called.should == true
      $after_destroy_called.should == true
      $before_destroy_called = false
      $after_destroy_called = false
    end
  end
end

describe "NameScope bug" do
  context "group named_scope" do
    it "should be equal to count(:group => '')" do
      Reply.group('replies.topic_id').count.should == Reply.count(:group => 'replies.topic_id')
    end
  end

  context "using multiple select statements" do
    it "should respect multiple select statements" do
      topics = Topic.select("distinct(topics.id)").select("topics.title as topic_title").first
      topics.topic_title.should_not be_nil
      topics.id.should_not be_nil
    end
  end
end

describe "using select with include" do
  it "should be able to use select with include" do
    Reply.create(:content => 'yeah', :topic_id => Topic.first)
    Topic.includes(:replies).select("topics.id as super_topic_id").where("replies.content = 'yeah'").first.super_topic_id.should_not be_nil
  end

  it "should allow named scopes to use select and include together" do
    Topic.select_only_id.all.map(&:super_duper_id).each {|t| t.should_not be_nil }
    Topic.send(:select_only_id).all.map(&:super_duper_id).each {|t| t.should_not be_nil }
  end
end

describe "#readonly" do
  it "should ensure records do not come back as readonly" do
    Topic.joins(:replies).readonly(false).first.readonly?.should be_false
  end
end

describe "from" do
  it "does the right thing with from" do
    Topic.from("topics").first.should eql(Topic.all.first)
  end
end
