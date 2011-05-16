## Fake_arel: Rails 3 Query Interface for Rails 2

http://github.com/gammons/fake_arel

## DESCRIPTION:

* Tired of waiting for Rails 3 and its new super-sweet query interface? Try fake_arel!

* Fake_arel is a gem that will simulate the new Rails 3 query interface, using named_scopes and a couple small patches to ActiveRecord.

* This should serve as a nice bridge between Rails 2 and Rails 3 apps, and can be removed once upgrading your app to rails 3, and everything (hopefully) should still work.

## SYNOPSIS:

* All the finders described on [Pratiks blog](http://m.onkey.org/2010/1/22/active-record-query-interface) have been implemented.

```ruby
Reply.where(:id => 1)
Reply.select("content,id").where("id > 1").order("id desc").limit(1)
Topic.joins(:replies).limit(1)
```

* Additionally, named_scopes are very similar to Rails 3 relations, in that they are lazily loaded.

```ruby
Reply.where(:name => "John").class
ActiveRecord::NamedScope::Scope
```
* Also implemented was `to_sql`. `to_sql` will work on any chained query. 

```ruby
Topic.joins(:replies).limit(1).to_sql
"SELECT \"topics\".* FROM \"topics\"   INNER JOIN \"replies\" ON replies.topic_id = topics.id   LIMIT 1"
```

* `named_scope` was modified to include other `named_scope`s, so you can chain them together. 

```ruby
class Reply < ActiveRecord::Base
  named_scope :by_john, where(:name => "John")
  named_scope :recent, lambda {|t| where("created_at > ? ", t.minutes.ago) }
  named_scope :recent_by_john, recent(15).by_john
end
```

## Recently Added!

* `or` syntax. Because named scopes load lazily, we are able to pass the scope to another scope, in this case, `or`.
```ruby
q1 = Reply.where(:id => 1)
q2 = Reply.where(:id => 2)
q3 = Reply.where(:id => 3)
q4 = Reply.where(:id => 4)

Reply.or(q1,q2).all.map(&:id)  # equals [1,2]
Reply.or(q1,q2,q3).all.map(&:id) # equals [1,2,3]

or1 = Reply.or(q1,q2)
or2 = Reply.or(q3,q4)
Reply.or(or1,or2).all.map(&:id) # equals [1,2,3,4]
```

* `fakearel_find_each`

The `find_each` that ships with ActiveRecord 2.x isn't very scope-friendly, thus using fakearel_find_each makes sense.  However I did not want to replace the original find_each functionality, just in case you were using it.

```ruby
Reply.where(:user_id => 1).fakearel_find_each do |reply|
  ...
end
```

* `fakearel_destroy`

Call destroy on a scoped call.  This will run any callbacks on the models to be destroyed.

```ruby
Reply.where(:user_id => 1).fakearel_destroy #will run before_destroy and after_destroy callbacks for affected Replys
```


## REQUIREMENTS:

* >= ActiveRecord 2.3.5

## INSTALL:

`gem install fake_arel`

## AUTHORS:

* Grant Ammons
* Sokolov Yura

## LICENSE:

(The MIT License)

Copyright (c) 2010 Grant Ammons (grant@pipelinedealsco.com)

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

