require File.dirname(__FILE__) + '/spec_helper.rb'
require 'reply'
require 'topic'


describe "Basics" do
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
    Reply.find_all_but_first.map(&:id).should == [2,3,4,5]
  end
end

describe "to sql" do
  it "should be able to output sql" do
    Topic.joins(:replies).limit(1).to_sql
  end
end
