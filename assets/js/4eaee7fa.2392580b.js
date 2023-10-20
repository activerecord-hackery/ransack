"use strict";(self.webpackChunkdocs_website=self.webpackChunkdocs_website||[]).push([[1719],{3905:function(t,e,n){n.d(e,{Zo:function(){return p},kt:function(){return g}});var r=n(7294);function o(t,e,n){return e in t?Object.defineProperty(t,e,{value:n,enumerable:!0,configurable:!0,writable:!0}):t[e]=n,t}function i(t,e){var n=Object.keys(t);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(t);e&&(r=r.filter((function(e){return Object.getOwnPropertyDescriptor(t,e).enumerable}))),n.push.apply(n,r)}return n}function a(t){for(var e=1;e<arguments.length;e++){var n=null!=arguments[e]?arguments[e]:{};e%2?i(Object(n),!0).forEach((function(e){o(t,e,n[e])})):Object.getOwnPropertyDescriptors?Object.defineProperties(t,Object.getOwnPropertyDescriptors(n)):i(Object(n)).forEach((function(e){Object.defineProperty(t,e,Object.getOwnPropertyDescriptor(n,e))}))}return t}function s(t,e){if(null==t)return{};var n,r,o=function(t,e){if(null==t)return{};var n,r,o={},i=Object.keys(t);for(r=0;r<i.length;r++)n=i[r],e.indexOf(n)>=0||(o[n]=t[n]);return o}(t,e);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(t);for(r=0;r<i.length;r++)n=i[r],e.indexOf(n)>=0||Object.prototype.propertyIsEnumerable.call(t,n)&&(o[n]=t[n])}return o}var c=r.createContext({}),l=function(t){var e=r.useContext(c),n=e;return t&&(n="function"==typeof t?t(e):a(a({},e),t)),n},p=function(t){var e=l(t.components);return r.createElement(c.Provider,{value:e},t.children)},u={inlineCode:"code",wrapper:function(t){var e=t.children;return r.createElement(r.Fragment,{},e)}},d=r.forwardRef((function(t,e){var n=t.components,o=t.mdxType,i=t.originalType,c=t.parentName,p=s(t,["components","mdxType","originalType","parentName"]),d=l(n),g=o,f=d["".concat(c,".").concat(g)]||d[g]||u[g]||i;return n?r.createElement(f,a(a({ref:e},p),{},{components:n})):r.createElement(f,a({ref:e},p))}));function g(t,e){var n=arguments,o=e&&e.mdxType;if("string"==typeof t||o){var i=n.length,a=new Array(i);a[0]=d;var s={};for(var c in e)hasOwnProperty.call(e,c)&&(s[c]=e[c]);s.originalType=t,s.mdxType="string"==typeof t?t:o,a[1]=s;for(var l=2;l<i;l++)a[l]=n[l];return r.createElement.apply(null,a)}return r.createElement.apply(null,n)}d.displayName="MDXCreateElement"},4713:function(t,e,n){n.r(e),n.d(e,{assets:function(){return c},contentTitle:function(){return a},default:function(){return u},frontMatter:function(){return i},metadata:function(){return s},toc:function(){return l}});var r=n(3117),o=(n(7294),n(3905));const i={title:"Sorting"},a="Sorting",s={unversionedId:"getting-started/sorting",id:"getting-started/sorting",title:"Sorting",description:"Sorting in the View",source:"@site/docs/getting-started/sorting.md",sourceDirName:"getting-started",slug:"/getting-started/sorting",permalink:"/ransack/getting-started/sorting",draft:!1,editUrl:"https://github.com/activerecord-hackery/ransack/edit/main/docs/docs/getting-started/sorting.md",tags:[],version:"current",frontMatter:{title:"Sorting"},sidebar:"tutorialSidebar",previous:{title:"Search Matchers",permalink:"/ransack/getting-started/search-matches"},next:{title:"Using Predicates",permalink:"/ransack/getting-started/using-predicates"}},c={},l=[{value:"Sorting in the View",id:"sorting-in-the-view",level:2},{value:"Sorting in the Controller",id:"sorting-in-the-controller",level:2}],p={toc:l};function u(t){let{components:e,...n}=t;return(0,o.kt)("wrapper",(0,r.Z)({},p,n,{components:e,mdxType:"MDXLayout"}),(0,o.kt)("h1",{id:"sorting"},"Sorting"),(0,o.kt)("h2",{id:"sorting-in-the-view"},"Sorting in the View"),(0,o.kt)("p",null,"You can add a form to capture sorting and filtering options together."),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-erb"},'# app/views/posts/index.html.erb\n\n<%= search_form_for @q do |f| %>\n  <%= f.label :title_cont %>\n  <%= f.search_field :title_cont %>\n\n  <%= f.submit "Search" %>\n<% end %>\n\n<table>\n  <thead>\n    <tr>\n      <th><%= sort_link(@q, :title, "Title") %></th>\n      <th><%= sort_link(@q, :category, "Category") %></th>\n      <th><%= sort_link(@q, :created_at, "Created at") %></th>\n    </tr>\n  </thead>\n\n  <tbody>\n    <% @posts.each do |post| %>\n      <tr>\n        <td><%= post.title %></td>\n        <td><%= post.category %></td>\n        <td><%= post.created_at.to_s(:long) %></td>\n      </tr>\n    <% end %>\n  </tbody>\n</table>\n')),(0,o.kt)("h2",{id:"sorting-in-the-controller"},"Sorting in the Controller"),(0,o.kt)("p",null,"To specify a default search sort field + order in the controller ",(0,o.kt)("inlineCode",{parentName:"p"},"index"),":"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-ruby"},"# app/controllers/posts_controller.rb\nclass PostsController < ActionController::Base\n  def index\n    @q = Post.ransack(params[:q])\n    @q.sorts = 'title asc' if @q.sorts.empty?\n\n    @posts = @q.result(distinct: true)\n  end\nend\n")),(0,o.kt)("p",null,"Multiple sorts can be set by:"),(0,o.kt)("pre",null,(0,o.kt)("code",{parentName:"pre",className:"language-ruby"},"# app/controllers/posts_controller.rb\nclass PostsController < ActionController::Base\n  def index\n    @q = Post.ransack(params[:q])\n    @q.sorts = ['title asc', 'created_at desc'] if @q.sorts.empty?\n\n    @posts = @q.result(distinct: true)\n  end\nend\n")))}u.isMDXComponent=!0}}]);