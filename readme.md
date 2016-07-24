ActiveContainer
===============

Trim the fatty models. Use ActiveContainer.

ActiveContainer doesn't just keep your models thin,
it keeps your tests away from the database.
Completely.
FactoryGirl's `build` and `build_stubbed` require db access.
And even RSpec ActiveModel Mocks can't avoid attempting to open a connection
when you call ANY function on the model.

You can get away from this easily and safely with ActiveContainer.

More to come...


Installation
------------

    $ gem install active_container


Gemfile
-------

    $ gem 'active_container'


Require
-------

    $ require 'active_container'


Usage
-----

Please note that this example is not necessarily for a Rails project.
In particular, namespacing may not need to be explicit.

Naming is important! Wrappers for `MyModel` *MUST* be named `MyModelWrapper`.


### Example

Let's wear out the blog post example:

```
# models/person.rb
class Person < ActiveRecord::Base
  has_many :posts

  validates :first_name, :presence => true
  validates :last_name, :presence => true
  validates :full_name, :presence => true

  validate :custom_validation

  def custom_validation
    # do custom validation
  end
end

# models/post.rb
class Post < ActiveRecord::Base
  has_one :author, :through => :person

  validates :title, :presence => true
  validates :body, :presence => true
end

# models/wrappers/post_wrapper.rb
class PostWrapper < ActiveContainer::Wrapper
end

# models/wrappers/person_wrapper.rb
class PersonWrapper < ActiveContainer::Wrapper
  include Wrappers::Person::FullName
  include Wrappers::Person::PostCount

  delegate :first_name, :last_name

  wrap_delegate :posts
end

# models/wrappers/person/full_name.rb
module Wrappers
  module Person
    module FullName
      def full_name
        "#{first_name} #{last_name}"
      end

      # This logic is overly simplified for example purposes only.
      def full_name=(value)
        names = value.split(' ')

        @record.full_name = value     # Must use `@record` here
        self.first_name = names.first # We can use either `@record` or `self`.
        self.last_name  = names.last  # We can use either `@record` or `self`.
      end
    end
  end
end

# models/wrappers/person/post_count.rb
module Wrappers
  module Person
    module PostCount
      def post_count
        post.count
      end
    end
  end
end

```

It is important that the helpers are included prior to calling
`delegate` as there are checks to ensure that assignment
methods do not already exist.

`ActiveContainer::Wrapper` automatically passes `id` to the underlying model,
so it does not need to be included in the list sent to `delegate`.


### Commentary

#### Goals

##### Reduce code in models (including `include` statements)

The only code that is left in the model is limited to ActiveRecord/ActiveModel
relationships, validations, etc.

These can get out of hand on their own in large projects.
This way, nothing but the essentials are in your models.


##### Increase test speed

One of the primary goals was to get completely away from the database
during testing.

This means not even so much as opening a connection
and this may not even be possible if you work with anything that has
knowledge of the ActiveRecord object you're working with.

This includes FactoryGirl's `build` and `build_stubbed`.
Even `mock_model` will attempt to open a database connection
if you call a method you haven't mocked out
(it wasn't mocked because we wanted to run the code!).


##### More explicit model interfaces

ActiveRecord models tell you little about what attributes you actually have.
You specify the methods that pass through to the underlying models,
so that interface is clearly seen when examining a Wrapper.

Along with this, it is recommended that functionality is grouped in *VERY SMALL*
chunks via mixins for the wrappers.

This allows easier testing of the mixins and tells you more about the interface
for the wrapper.


##### Encapsulation of model lifecycle events.

ActiveRecord callbacks are the devil's work.
ActiveContainer lets you take control again.

It can be used only for that, if you like:

    $ Person.new(:first_name => 'John').wrap.save # where save has custom logic

A simple example:

```
# models/wrappers/person_wrapper.rb
class PersonWrapper < ActiveContainer::Wrapper
  def save
    if !@record.save
      # do something
    end
  end
end
```


If you want to apply logic to all models, simply create your own BaseWrapper:

```
# models/wrappers/base_wrapper.rb
class BaseWrapper < ActiveContainer::Wrapper
  def save
    if !@record.save
      # do something
    end
  end
end

# models/wrappers/person_wrapper.rb
class PersonWrapper < BaseWrapper
  def save
    if !@record.save
      # do something
    end
  end
end
```


Testing
-------

Like Drake, let's start at the bottom.

```
#spec/models/wrappers/person/full_name_spec.rb
# It is expected that `spec_helper` will load you files
# without even THINKING about a database connection.
require 'spec_helper'

RSpec.describe Wrappers::Person::FullName do
  subject { PersonWrapper.new person }

  let(:person) do
    OpenStruct.new \
      :first_name => first_name,
      :last_name  => last_name,
  end

  describe '#full_name' do
    shared_examples_for 'a full name' do |first, last, expected|
      context "given a first name of #{first.inspect}" do
        let(:first_name) { first_name }

        context "given a last name of #{last.inspect}" do
          let(:last_name) { last_name }

          it "returns #{expected.inspect}" do
            expect(subject.full_name).to eq expected
          end
        end
      end
    end

    it_behaves_like 'a full name', 'Tom', 'Jones', 'Tom Jones'
    it_behaves_like 'a full name', 'Tiny ', ' Tim ', 'Tiny  Tim '
  end
end

#spec/models/wrappers/person_wrapper_spec.rb
require 'spec/app_helper' # or rails_helper or whatever includes the full app.
RSpec.describe PersonWrapper do
  subject { PersonWrapper.new person }

  let(:person) do
    # this or FactoryGirl.build_stubbed
    Person.new \
      :first_name => first_name,
      :last_name  => last_name,
  end

  describe '#full_name' do
    context 'given first and last name of Dizzy and Gillespie' do
      let(:first_name) { 'Dizzy' }
      let(:last_name)  { 'Gillespie' }

      it 'returns Dizzy Gillespie' do
        expect(subject.full_name).to eq 'Dizzy Gillespie'
      end
    end
  end
end
```


### Notes

The `PersonWrapper` is a fairly poor example.
The important thing here is that `#full_name`
gets called *at some point* in this group of tests.

It is not important that it be tested explicitly.
By reducing the number of tests at this level to be just enough
to ensure integration with the individual components (including the model),
we can speed up our test suite dramatically.

The biggest concern at this level is not whether the logic is correct,
but whether we have changed attribute names without updating
the mocked objects we use at the lower level.

This is the tradeoff.
