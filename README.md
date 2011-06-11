# Ransack

Ransack is a rewrite of [MetaSearch](http://metautonomo.us/projects/metasearch). While it
supports many of the same features as MetaSearch, its underlying implementation differs
greatly from MetaSearch, and _backwards compatibility is not a design goal._

Ransack enables the creation of both simple and [advanced](http://ransack-demo.heroku.com)
search forms against your application's models. If you're looking for something that
simplifies query generation at the model or controller layer, you're probably not looking
for Ransack (or MetaSearch, for that matter). Try 
[Squeel](http://metautonomo.us/projects/squeel) instead.

## Getting started

In your Gemfile:

    gem "ransack"  # Last officially released gem
    # gem "ransack", :git => "git://github.com/ernie/ransack.git" # Track git repo

If you'd like to add your own custom Ransack predicates:

    Ransack.configure do |config|
      config.add_predicate 'equals_diddly', # Name your predicate
                           # What non-compound ARel predicate will it use? (eq, matches, etc)
                           :arel_predicate => 'eq',
                           # Format incoming values as you see fit. (Default: Don't do formatting)
                           :formatter => proc {|v| "#{v}-diddly"},
                           # Validate a value. An "invalid" value won't be used in a search.
                           # Below is default.
                           :validator => proc {|v| v.present?},
                           # Should compounds be created? Will use the compound (any/all) version
                           # of the arel_predicate to create a corresponding any/all version of
                           # your predicate. (Default: true)
                           :compounds => true,
                           # Force a specific column type for type-casting of supplied values.
                           # (Default: use type from DB column)
                           :type => :string
    end

## Usage

Ransack can be used in one of two modes, simple or advanced.

### Simple Mode

This mode works much like MetaSearch, for those of you who are familiar with it, and
requires very little setup effort.

If you're coming from MetaSearch, things to note:

  1. The default param key for search params is now `:q`, instead of `:search`. This is
     primarily to shorten query strings, though advanced queries (below) will still 
     run afoul of URL length limits in most browsers and require a switch to HTTP 
     POST requests.
  2. `form_for` is now `search_form_for`, and validates that a Ransack::Search object
     is passed to it.
  3. Common ActiveRecord::Relation methods are no longer delegated by the search object.
     Instead, you will get your search results (an ActiveRecord::Relation in the case of
     the ActiveRecord adapter) via a call to `Search#result`. If passed `:distinct => true`,
     `result` will generate a `SELECT DISTINCT` to avoid returning duplicate rows, even if
     conditions on a join would otherwise result in some.
     
     Please note that for many databases, a sort on an associated table's columns will
     result in invalid SQL with `:distinct => true` -- in those cases, you're on your own,
     and will need to modify the result as needed to allow these queries to work. Thankfully,
     9 times out of 10, sort against the search's base is sufficient, though, as that's
     generally what's being displayed on your results page.

In your controller:

    def index
      @q = Person.search(params[:q])
      @people = @q.result(:distinct => true)
    end

In your view:

    <%= search_form_for @q do |f| %>
      <%= f.label :name_cont %>
      <%= f.text_field :name_cont %>
      <%= f.label :articles_title_start %>
      <%= f.text_field :articles_title_start %>
      <%= f.submit %>
    <% end %>

`cont` (contains) and `start` (starts with) are just two of the available search predicates.
See Constants for a full list.
    
### Advanced Mode

"Advanced" searches (ab)use Rails' nested attributes functionality in order to generate
complex queries with nested AND/OR groupings, etc. This takes a bit more work but can
generate some pretty cool search interfaces that put a lot of power in the hands of
your users. A notable drawback with these searches is that the increased size of the
parameter string will typically force you to use the HTTP POST method instead of GET. :(

This means you'll need to tweak your routes...

    resources :people do
      collection do
        match 'search' => 'people#search', :via => [:get, :post], :as => :search
      end
    end

... and add another controller action ...

    def search
      index
      render :index
    end
    
... and update your `search_form_for` line in the view ...

    <%= search_form_for @q, :url => search_people_path, 
                            :html => {:method => :post} do |f| %>

Once you've done so, you can make use of the helpers in Ransack::Helpers::FormBuilder to
construct much more complex search forms, such as the one on the
[demo page](http://ransack-demo.heroku.com).

**more docs to come**

## Contributions

If you'd like to support the continued development of Ransack, please consider
[making a donation](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=48Q9HY64L3TWA).

To support the project in other ways:

* Use Ransack in your apps, and let me know if you encounter anything that's broken or missing.
  A failing spec is awesome. A pull request is even better!
* Spread the word on Twitter, Facebook, and elsewhere if Ransack's been useful to you. The more
  people who are using the project, the quicker we can find and fix bugs!

## Copyright

Copyright &copy; 2011 [Ernie Miller](http://twitter.com/erniemiller)