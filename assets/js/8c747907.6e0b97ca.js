"use strict";(self.webpackChunkdocs_website=self.webpackChunkdocs_website||[]).push([[2364],{3905:function(e,n,t){t.d(n,{Zo:function(){return u},kt:function(){return m}});var a=t(7294);function r(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function i(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var a=Object.getOwnPropertySymbols(e);n&&(a=a.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,a)}return t}function o(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?i(Object(t),!0).forEach((function(n){r(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):i(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function s(e,n){if(null==e)return{};var t,a,r=function(e,n){if(null==e)return{};var t,a,r={},i=Object.keys(e);for(a=0;a<i.length;a++)t=i[a],n.indexOf(t)>=0||(r[t]=e[t]);return r}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(a=0;a<i.length;a++)t=i[a],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(r[t]=e[t])}return r}var l=a.createContext({}),c=function(e){var n=a.useContext(l),t=n;return e&&(t="function"==typeof e?e(n):o(o({},n),e)),t},u=function(e){var n=c(e.components);return a.createElement(l.Provider,{value:n},e.children)},p={inlineCode:"code",wrapper:function(e){var n=e.children;return a.createElement(a.Fragment,{},n)}},d=a.forwardRef((function(e,n){var t=e.components,r=e.mdxType,i=e.originalType,l=e.parentName,u=s(e,["components","mdxType","originalType","parentName"]),d=c(t),m=r,h=d["".concat(l,".").concat(m)]||d[m]||p[m]||i;return t?a.createElement(h,o(o({ref:n},u),{},{components:t})):a.createElement(h,o({ref:n},u))}));function m(e,n){var t=arguments,r=n&&n.mdxType;if("string"==typeof e||r){var i=t.length,o=new Array(i);o[0]=d;var s={};for(var l in n)hasOwnProperty.call(n,l)&&(s[l]=n[l]);s.originalType=e,s.mdxType="string"==typeof e?e:r,o[1]=s;for(var c=2;c<i;c++)o[c]=t[c];return a.createElement.apply(null,o)}return a.createElement.apply(null,t)}d.displayName="MDXCreateElement"},4910:function(e,n,t){t.r(n),t.d(n,{assets:function(){return l},contentTitle:function(){return o},default:function(){return p},frontMatter:function(){return i},metadata:function(){return s},toc:function(){return c}});var a=t(3117),r=(t(7294),t(3905));const i={sidebar_position:8,title:"Other notes"},o=void 0,s={unversionedId:"going-further/other-notes",id:"going-further/other-notes",title:"Other notes",description:"Ransack Aliases",source:"@site/docs/going-further/other-notes.md",sourceDirName:"going-further",slug:"/going-further/other-notes",permalink:"/ransack/going-further/other-notes",draft:!1,editUrl:"https://github.com/activerecord-hackery/ransack/edit/main/docs/docs/going-further/other-notes.md",tags:[],version:"current",sidebarPosition:8,frontMatter:{sidebar_position:8,title:"Other notes"},sidebar:"tutorialSidebar",previous:{title:"Saving queries",permalink:"/ransack/going-further/saving-queries"},next:{title:"Postgres searches",permalink:"/ransack/going-further/searching-postgres"}},l={},c=[{value:"Ransack Aliases",id:"ransack-aliases",level:3},{value:"Problem with DISTINCT selects",id:"problem-with-distinct-selects",level:3},{value:"<code>PG::UndefinedFunction: ERROR: could not identify an equality operator for type json</code>",id:"pgundefinedfunction-error-could-not-identify-an-equality-operator-for-type-json",level:4},{value:"Authorization (allowlisting/denylisting)",id:"authorization-allowlistingdenylisting",level:3},{value:"Handling unknown predicates or attributes",id:"handling-unknown-predicates-or-attributes",level:3},{value:"Using Scopes/Class Methods",id:"using-scopesclass-methods",level:3},{value:"Grouping queries by OR instead of AND",id:"grouping-queries-by-or-instead-of-and",level:3},{value:"Using SimpleForm",id:"using-simpleform",level:3}],u={toc:c};function p(e){let{components:n,...t}=e;return(0,r.kt)("wrapper",(0,a.Z)({},u,t,{components:n,mdxType:"MDXLayout"}),(0,r.kt)("h3",{id:"ransack-aliases"},"Ransack Aliases"),(0,r.kt)("p",null,"You can customize the attribute names for your Ransack searches by using a\n",(0,r.kt)("inlineCode",{parentName:"p"},"ransack_alias"),". This is particularly useful for long attribute names that are\nnecessary when querying associations or multiple columns."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"class Post < ActiveRecord::Base\n  belongs_to :author\n\n  # Abbreviate :author_first_name_or_author_last_name to :author\n  ransack_alias :author, :author_first_name_or_author_last_name\nend\n")),(0,r.kt)("p",null,"Now, rather than using ",(0,r.kt)("inlineCode",{parentName:"p"},":author_first_name_or_author_last_name_cont")," in your\nform, you can simply use ",(0,r.kt)("inlineCode",{parentName:"p"},":author_cont"),". This serves to produce more expressive\nquery parameters in your URLs."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-erb"},"<%= search_form_for @q do |f| %>\n  <%= f.label :author_cont %>\n  <%= f.search_field :author_cont %>\n<% end %>\n")),(0,r.kt)("p",null,"You can also use ",(0,r.kt)("inlineCode",{parentName:"p"},"ransack_alias")," for sorting."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"class Post < ActiveRecord::Base\n  belongs_to :author\n\n  # Abbreviate :author_first_name to :author\n  ransack_alias :author, :author_first_name\nend\n")),(0,r.kt)("p",null,"Now, you can use ",(0,r.kt)("inlineCode",{parentName:"p"},":author")," instead of ",(0,r.kt)("inlineCode",{parentName:"p"},":author_first_name")," in a ",(0,r.kt)("inlineCode",{parentName:"p"},"sort_link"),"."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-erb"},"<%= sort_link(@q, :author) %>\n")),(0,r.kt)("p",null,"Note that using ",(0,r.kt)("inlineCode",{parentName:"p"},":author_first_name_or_author_last_name_cont")," would produce an invalid sql query. In those cases, Ransack ignores the sorting clause."),(0,r.kt)("h3",{id:"problem-with-distinct-selects"},"Problem with DISTINCT selects"),(0,r.kt)("p",null,"If passed ",(0,r.kt)("inlineCode",{parentName:"p"},"distinct: true"),", ",(0,r.kt)("inlineCode",{parentName:"p"},"result")," will generate a ",(0,r.kt)("inlineCode",{parentName:"p"},"SELECT DISTINCT")," to\navoid returning duplicate rows, even if conditions on a join would otherwise\nresult in some. It generates the same SQL as calling ",(0,r.kt)("inlineCode",{parentName:"p"},"uniq")," on the relation."),(0,r.kt)("p",null,"Please note that for many databases, a sort on an associated table's columns\nmay result in invalid SQL with ",(0,r.kt)("inlineCode",{parentName:"p"},"distinct: true")," -- in those cases, you\nwill need to modify the result as needed to allow these queries to work."),(0,r.kt)("p",null,"For example, you could call joins and includes on the result which has the\neffect of adding those tables columns to the select statement, overcoming\nthe issue, like so:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"def index\n  @q = Person.ransack(params[:q])\n  @people = @q.result(distinct: true)\n              .includes(:articles)\n              .joins(:articles)\n              .page(params[:page])\nend\n")),(0,r.kt)("p",null,"If the above doesn't help, you can also use ActiveRecord's ",(0,r.kt)("inlineCode",{parentName:"p"},"select")," query\nto explicitly add the columns you need, which brute force's adding the\ncolumns you need that your SQL engine is complaining about, you need to\nmake sure you give all of the columns you care about, for example:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"def index\n  @q = Person.ransack(params[:q])\n  @people = @q.result(distinct: true)\n              .select('people.*, articles.name, articles.description')\n              .page(params[:page])\nend\n")),(0,r.kt)("p",null,"Another method to approach this when using Postgresql is to use ActiveRecords's ",(0,r.kt)("inlineCode",{parentName:"p"},".includes")," in combination with ",(0,r.kt)("inlineCode",{parentName:"p"},".group")," instead of ",(0,r.kt)("inlineCode",{parentName:"p"},"distinct: true"),"."),(0,r.kt)("p",null,"For example:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"def index\n  @q = Person.ransack(params[:q])\n  @people = @q.result\n              .group('persons.id')\n              .includes(:articles)\n              .page(params[:page])\nend\n\n")),(0,r.kt)("p",null,"A final way of last resort is to call ",(0,r.kt)("inlineCode",{parentName:"p"},"to_a.uniq")," on the collection at the end\nwith the caveat that the de-duping is taking place in Ruby instead of in SQL,\nwhich is potentially slower and uses more memory, and that it may display\nawkwardly with pagination if the number of results is greater than the page size."),(0,r.kt)("p",null,"For example:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"def index\n  @q = Person.ransack(params[:q])\n  @people = @q.result.includes(:articles).page(params[:page]).to_a.uniq\nend\n")),(0,r.kt)("h4",{id:"pgundefinedfunction-error-could-not-identify-an-equality-operator-for-type-json"},(0,r.kt)("inlineCode",{parentName:"h4"},"PG::UndefinedFunction: ERROR: could not identify an equality operator for type json")),(0,r.kt)("p",null,"If you get the above error while using ",(0,r.kt)("inlineCode",{parentName:"p"},"distinct: true")," that means that\none of the columns that Ransack is selecting is a ",(0,r.kt)("inlineCode",{parentName:"p"},"json")," column.\nPostgreSQL does not provide comparison operators for the ",(0,r.kt)("inlineCode",{parentName:"p"},"json")," type.  While\nit is possible to work around this, in practice it's much better to convert those\nto ",(0,r.kt)("inlineCode",{parentName:"p"},"jsonb"),", as ",(0,r.kt)("a",{parentName:"p",href:"https://www.postgresql.org/docs/9.6/static/datatype-json.html"},"recommended by the PostgreSQL documentation"),"."),(0,r.kt)("h3",{id:"authorization-allowlistingdenylisting"},"Authorization (allowlisting/denylisting)"),(0,r.kt)("p",null,"By default, searching and sorting are not authorized on any column of your model\nand no class methods/scopes are allowlisted."),(0,r.kt)("p",null,"Ransack adds four methods to ",(0,r.kt)("inlineCode",{parentName:"p"},"ActiveRecord::Base")," that you can redefine as\nclass methods in your models to apply selective authorization:"),(0,r.kt)("ul",null,(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"ransackable_attributes")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"ransackable_associations")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"ransackable_scopes")),(0,r.kt)("li",{parentName:"ul"},(0,r.kt)("inlineCode",{parentName:"li"},"ransortable_attributes"))),(0,r.kt)("p",null,"Here is how these four methods could be implemented in your application:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"  # `ransackable_attributes` returns searchable column names\n  # and any defined ransackers as an array of strings.\n  #\n  def ransackable_attributes(auth_object = nil)\n    %w(title body) + _ransackers.keys\n  end\n\n  # `ransackable_associations` returns the names\n  # of searchable associations as an array of strings.\n  #\n  def ransackable_associations(auth_object = nil)\n    %w[author]\n  end\n\n  # `ransortable_attributes` by default returns the names\n  # of all attributes available for sorting as an array of strings.\n  #\n  def ransortable_attributes(auth_object = nil)\n    ransackable_attributes(auth_object)\n  end\n\n  # `ransackable_scopes` by default returns an empty array\n  # i.e. no class methods/scopes are authorized.\n  # For overriding with an allowlist, return an array of *symbols*.\n  #\n  def ransackable_scopes(auth_object = nil)\n    []\n  end\n")),(0,r.kt)("p",null,"Any values not returned from these methods will be ignored by Ransack, i.e.\nthey are not authorized."),(0,r.kt)("p",null,"All four methods can receive a single optional parameter, ",(0,r.kt)("inlineCode",{parentName:"p"},"auth_object"),". When\nyou call the search or ransack method on your model, you can provide a value\nfor an ",(0,r.kt)("inlineCode",{parentName:"p"},"auth_object")," key in the options hash which can be used by your own\noverridden methods."),(0,r.kt)("p",null,"Here is an example that puts all this together, adapted from\n",(0,r.kt)("a",{parentName:"p",href:"https://ernie.io/2012/05/11/why-your-ruby-class-macros-might-suck-mine-did/"},"this blog post by Ernie Miller"),".\nIn an ",(0,r.kt)("inlineCode",{parentName:"p"},"Article")," model, add the following ",(0,r.kt)("inlineCode",{parentName:"p"},"ransackable_attributes")," class method\n(preferably private):"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"class Article < ActiveRecord::Base\n  def self.ransackable_attributes(auth_object = nil)\n    if auth_object == :admin\n      # allow all attributes for admin\n      column_names + _ransackers.keys\n    else\n      # allow only the title and body attributes for other users\n      %w(title body)\n    end\n  end\n\n  private_class_method :ransackable_attributes\nend\n")),(0,r.kt)("p",null,"Here is example code for the ",(0,r.kt)("inlineCode",{parentName:"p"},"articles_controller"),":"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"class ArticlesController < ApplicationController\n  def index\n    @q = Article.ransack(params[:q], auth_object: set_ransack_auth_object)\n    @articles = @q.result\n  end\n\n  private\n\n  def set_ransack_auth_object\n    current_user.admin? ? :admin : nil\n  end\nend\n")),(0,r.kt)("p",null,"Trying it out in ",(0,r.kt)("inlineCode",{parentName:"p"},"rails console"),":"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},'> Article\n=> Article(id: integer, person_id: integer, title: string, body: text)\n\n> Article.ransackable_attributes\n=> ["title", "body"]\n\n> Article.ransackable_attributes(:admin)\n=> ["id", "person_id", "title", "body"]\n\n> Article.ransack(id_eq: 1).result.to_sql\n=> SELECT "articles".* FROM "articles"  # Note that search param was ignored!\n\n> Article.ransack({ id_eq: 1 }, { auth_object: nil }).result.to_sql\n=> SELECT "articles".* FROM "articles"  # Search param still ignored!\n\n> Article.ransack({ id_eq: 1 }, { auth_object: :admin }).result.to_sql\n=> SELECT "articles".* FROM "articles"  WHERE "articles"."id" = 1\n')),(0,r.kt)("p",null,"That's it! Now you know how to allow/block various elements in Ransack."),(0,r.kt)("h3",{id:"handling-unknown-predicates-or-attributes"},"Handling unknown predicates or attributes"),(0,r.kt)("p",null,"By default, Ransack will ignore any unknown predicates or attributes:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},'Article.ransack(unknown_attr_eq: \'Ernie\').result.to_sql\n=> SELECT "articles".* FROM "articles"\n')),(0,r.kt)("p",null,"Ransack may be configured to raise an error if passed an unknown predicate or\nattributes, by setting the ",(0,r.kt)("inlineCode",{parentName:"p"},"ignore_unknown_conditions")," option to ",(0,r.kt)("inlineCode",{parentName:"p"},"false")," in your\nRansack initializer file at ",(0,r.kt)("inlineCode",{parentName:"p"},"config/initializers/ransack.rb"),":"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"Ransack.configure do |c|\n  # Raise errors if a query contains an unknown predicate or attribute.\n  # Default is true (do not raise error on unknown conditions).\n  c.ignore_unknown_conditions = false\nend\n")),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"Article.ransack(unknown_attr_eq: 'Ernie')\n# ArgumentError (Invalid search term unknown_attr_eq)\n")),(0,r.kt)("p",null,"As an alternative to setting a global configuration option, the ",(0,r.kt)("inlineCode",{parentName:"p"},".ransack!"),"\nclass method also raises an error if passed an unknown condition:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"Article.ransack!(unknown_attr_eq: 'Ernie')\n# ArgumentError: Invalid search term unknown_attr_eq\n")),(0,r.kt)("p",null,"This is equivalent to the ",(0,r.kt)("inlineCode",{parentName:"p"},"ignore_unknown_conditions")," configuration option,\nexcept it may be applied on a case-by-case basis."),(0,r.kt)("h3",{id:"using-scopesclass-methods"},"Using Scopes/Class Methods"),(0,r.kt)("p",null,"Continuing on from the preceding section, searching by scopes requires defining\na whitelist of ",(0,r.kt)("inlineCode",{parentName:"p"},"ransackable_scopes")," on the model class. The whitelist should be\nan array of ",(0,r.kt)("em",{parentName:"p"},"symbols"),". By default, all class methods (e.g. scopes) are ignored.\nScopes will be applied for matching ",(0,r.kt)("inlineCode",{parentName:"p"},"true")," values, or for given values if the\nscope accepts a value:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"class Employee < ActiveRecord::Base\n  scope :activated, ->(boolean = true) { where(active: boolean) }\n  scope :salary_gt, ->(amount) { where('salary > ?', amount) }\n\n  # Scopes are just syntactical sugar for class methods, which may also be used:\n\n  def self.hired_since(date)\n    where('start_date >= ?', date)\n  end\n\n  def self.ransackable_scopes(auth_object = nil)\n    if auth_object.try(:admin?)\n      # allow admin users access to all three methods\n      %i(activated hired_since salary_gt)\n    else\n      # allow other users to search on `activated` and `hired_since` only\n      %i(activated hired_since)\n    end\n  end\nend\n\nEmployee.ransack({ activated: true, hired_since: '2013-01-01' })\n\nEmployee.ransack({ salary_gt: 100_000 }, { auth_object: current_user })\n")),(0,r.kt)("p",null,"In Rails 3 and 4, if the ",(0,r.kt)("inlineCode",{parentName:"p"},"true")," value is being passed via url params or some\nother mechanism that will convert it to a string, the true value may not be\npassed to the ransackable scope unless you wrap it in an array\n(i.e. ",(0,r.kt)("inlineCode",{parentName:"p"},"activated: ['true']"),"). Ransack will take care of changing 'true' into a\nboolean. This is currently resolved in Rails 5 \ud83d\ude03"),(0,r.kt)("p",null,"However, perhaps you have ",(0,r.kt)("inlineCode",{parentName:"p"},"user_id: [1]")," and you do not want Ransack to convert\n1 into a boolean. (Values sanitized to booleans can be found in the\n",(0,r.kt)("a",{parentName:"p",href:"https://github.com/activerecord-hackery/ransack/blob/master/lib/ransack/constants.rb#L28"},"constants.rb"),").\nTo turn this off globally, and handle type conversions yourself, set\n",(0,r.kt)("inlineCode",{parentName:"p"},"sanitize_custom_scope_booleans")," to false in an initializer file like\nconfig/initializers/ransack.rb:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"Ransack.configure do |c|\n  c.sanitize_custom_scope_booleans = false\nend\n")),(0,r.kt)("p",null,"To turn this off on a per-scope basis Ransack adds the following method to\n",(0,r.kt)("inlineCode",{parentName:"p"},"ActiveRecord::Base")," that you can redefine to selectively override sanitization:"),(0,r.kt)("p",null,(0,r.kt)("inlineCode",{parentName:"p"},"ransackable_scopes_skip_sanitize_args")),(0,r.kt)("p",null,"Add the scope you wish to bypass this behavior to ransackable_scopes_skip_sanitize_args:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"def self.ransackable_scopes_skip_sanitize_args\n  [:scope_to_skip_sanitize_args]\nend\n")),(0,r.kt)("p",null,"Scopes are a recent addition to Ransack and currently have a few caveats:\nFirst, a scope involving child associations needs to be defined in the parent\ntable model, not in the child model. Second, scopes with an array as an\nargument are not easily usable yet, because the array currently needs to be\nwrapped in an array to function (see\n",(0,r.kt)("a",{parentName:"p",href:"https://github.com/activerecord-hackery/ransack/issues/404"},"this issue"),"),\nwhich is not compatible with Ransack form helpers. For this use case, it may be\nbetter for now to use ",(0,r.kt)("a",{parentName:"p",href:"https://activerecord-hackery.github.io/ransack/going-further/ransackers"},"ransackers")," instead,\nwhere feasible. Pull requests with solutions and tests are welcome!"),(0,r.kt)("h3",{id:"grouping-queries-by-or-instead-of-and"},"Grouping queries by OR instead of AND"),(0,r.kt)("p",null,"The default ",(0,r.kt)("inlineCode",{parentName:"p"},"AND")," grouping can be changed to ",(0,r.kt)("inlineCode",{parentName:"p"},"OR")," by adding ",(0,r.kt)("inlineCode",{parentName:"p"},"m: 'or'")," to the\nquery hash."),(0,r.kt)("p",null,"You can easily try it in your controller code by changing ",(0,r.kt)("inlineCode",{parentName:"p"},"params[:q]")," in the\n",(0,r.kt)("inlineCode",{parentName:"p"},"index")," action to ",(0,r.kt)("inlineCode",{parentName:"p"},"params[:q].try(:merge, m: 'or')")," as follows:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"def index\n  @q = Artist.ransack(params[:q].try(:merge, m: 'or'))\n  @artists = @q.result\nend\n")),(0,r.kt)("p",null,"Normally, if you wanted users to be able to toggle between ",(0,r.kt)("inlineCode",{parentName:"p"},"AND")," and ",(0,r.kt)("inlineCode",{parentName:"p"},"OR"),"\nquery grouping, you would probably set up your search form so that ",(0,r.kt)("inlineCode",{parentName:"p"},"m")," was in\nthe URL params hash, but here we assigned ",(0,r.kt)("inlineCode",{parentName:"p"},"m")," manually just to try it out\nquickly."),(0,r.kt)("p",null,"Alternatively, trying it in the Rails console:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},'artists = Artist.ransack(name_cont: \'foo\', style_cont: \'bar\', m: \'or\')\n=> Ransack::Search<class: Artist, base: Grouping <conditions: [\n  Condition <attributes: ["name"], predicate: cont, values: ["foo"]>,\n  Condition <attributes: ["style"], predicate: cont, values: ["bar"]>\n  ], combinator: or>>\n\nartists.result.to_sql\n=> "SELECT \\"artists\\".* FROM \\"artists\\"\n    WHERE ((\\"artists\\".\\"name\\" ILIKE \'%foo%\'\n    OR \\"artists\\".\\"style\\" ILIKE \'%bar%\'))"\n')),(0,r.kt)("p",null,"The combinator becomes ",(0,r.kt)("inlineCode",{parentName:"p"},"or")," instead of the default ",(0,r.kt)("inlineCode",{parentName:"p"},"and"),", and the SQL query\nbecomes ",(0,r.kt)("inlineCode",{parentName:"p"},"WHERE...OR")," instead of ",(0,r.kt)("inlineCode",{parentName:"p"},"WHERE...AND"),"."),(0,r.kt)("p",null,"This works with associations as well. Imagine an Artist model that has many\nMemberships, and many Musicians through Memberships:"),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},'artists = Artist.ransack(name_cont: \'foo\', musicians_email_cont: \'bar\', m: \'or\')\n=> Ransack::Search<class: Artist, base: Grouping <conditions: [\n  Condition <attributes: ["name"], predicate: cont, values: ["foo"]>,\n  Condition <attributes: ["musicians_email"], predicate: cont, values: ["bar"]>\n  ], combinator: or>>\n\nartists.result.to_sql\n=> "SELECT \\"artists\\".* FROM \\"artists\\"\n    LEFT OUTER JOIN \\"memberships\\"\n      ON \\"memberships\\".\\"artist_id\\" = \\"artists\\".\\"id\\"\n    LEFT OUTER JOIN \\"musicians\\"\n      ON \\"musicians\\".\\"id\\" = \\"memberships\\".\\"musician_id\\"\n    WHERE ((\\"artists\\".\\"name\\" ILIKE \'%foo%\'\n    OR \\"musicians\\".\\"email\\" ILIKE \'%bar%\'))"\n')),(0,r.kt)("h3",{id:"using-simpleform"},"Using SimpleForm"),(0,r.kt)("p",null,"If you would like to combine the Ransack and SimpleForm form builders, set the\n",(0,r.kt)("inlineCode",{parentName:"p"},"RANSACK_FORM_BUILDER")," environment variable before Rails boots up, e.g. in\n",(0,r.kt)("inlineCode",{parentName:"p"},"config/application.rb")," before ",(0,r.kt)("inlineCode",{parentName:"p"},"require 'rails/all'")," as shown below (and add\n",(0,r.kt)("inlineCode",{parentName:"p"},"gem 'simple_form'")," in your Gemfile)."),(0,r.kt)("pre",null,(0,r.kt)("code",{parentName:"pre",className:"language-ruby"},"require File.expand_path('../boot', __FILE__)\nENV['RANSACK_FORM_BUILDER'] = '::SimpleForm::FormBuilder'\nrequire 'rails/all'\n")))}p.isMDXComponent=!0}}]);