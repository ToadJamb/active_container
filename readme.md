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
