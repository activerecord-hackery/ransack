"use strict";(self.webpackChunkdocs_website=self.webpackChunkdocs_website||[]).push([[3436],{3905:function(e,n,t){t.d(n,{Zo:function(){return u},kt:function(){return f}});var r=t(7294);function a(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function i(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function o(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?i(Object(t),!0).forEach((function(n){a(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):i(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function c(e,n){if(null==e)return{};var t,r,a=function(e,n){if(null==e)return{};var t,r,a={},i=Object.keys(e);for(r=0;r<i.length;r++)t=i[r],n.indexOf(t)>=0||(a[t]=e[t]);return a}(e,n);if(Object.getOwnPropertySymbols){var i=Object.getOwnPropertySymbols(e);for(r=0;r<i.length;r++)t=i[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(a[t]=e[t])}return a}var s=r.createContext({}),l=function(e){var n=r.useContext(s),t=n;return e&&(t="function"==typeof e?e(n):o(o({},n),e)),t},u=function(e){var n=l(e.components);return r.createElement(s.Provider,{value:n},e.children)},p={inlineCode:"code",wrapper:function(e){var n=e.children;return r.createElement(r.Fragment,{},n)}},d=r.forwardRef((function(e,n){var t=e.components,a=e.mdxType,i=e.originalType,s=e.parentName,u=c(e,["components","mdxType","originalType","parentName"]),d=l(t),f=a,m=d["".concat(s,".").concat(f)]||d[f]||p[f]||i;return t?r.createElement(m,o(o({ref:n},u),{},{components:t})):r.createElement(m,o({ref:n},u))}));function f(e,n){var t=arguments,a=n&&n.mdxType;if("string"==typeof e||a){var i=t.length,o=new Array(i);o[0]=d;var c={};for(var s in n)hasOwnProperty.call(n,s)&&(c[s]=n[s]);c.originalType=e,c.mdxType="string"==typeof e?e:a,o[1]=c;for(var l=2;l<i;l++)o[l]=t[l];return r.createElement.apply(null,o)}return r.createElement.apply(null,t)}d.displayName="MDXCreateElement"},2783:function(e,n,t){t.r(n),t.d(n,{assets:function(){return u},contentTitle:function(){return s},default:function(){return f},frontMatter:function(){return c},metadata:function(){return l},toc:function(){return p}});var r=t(3117),a=t(102),i=(t(7294),t(3905)),o=["components"],c={sidebar_position:3,title:"Configuration"},s=void 0,l={unversionedId:"getting-started/configuration",id:"getting-started/configuration",title:"Configuration",description:"Ransack may be easily configured. The best place to put configuration is in an initializer file at config/initializers/ransack.rb, containing code such as:",source:"@site/docs/getting-started/configuration.md",sourceDirName:"getting-started",slug:"/getting-started/configuration",permalink:"/ransack/getting-started/configuration",draft:!1,editUrl:"https://github.com/activerecord-hackery/ransack/edit/main/docs/docs/getting-started/configuration.md",tags:[],version:"current",sidebarPosition:3,frontMatter:{sidebar_position:3,title:"Configuration"},sidebar:"tutorialSidebar",previous:{title:"Advanced Mode",permalink:"/ransack/getting-started/advanced-mode"},next:{title:"Search Matchers",permalink:"/ransack/getting-started/search-matches"}},u={},p=[{value:"Custom search parameter key name",id:"custom-search-parameter-key-name",level:2},{value:"In the controller",id:"in-the-controller",level:3},{value:"In the view",id:"in-the-view",level:3}],d={toc:p};function f(e){var n=e.components,t=(0,a.Z)(e,o);return(0,i.kt)("wrapper",(0,r.Z)({},d,t,{components:n,mdxType:"MDXLayout"}),(0,i.kt)("p",null,"Ransack may be easily configured. The best place to put configuration is in an initializer file at ",(0,i.kt)("inlineCode",{parentName:"p"},"config/initializers/ransack.rb"),", containing code such as:"),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre",className:"language-ruby"},"Ransack.configure do |config|\n\n  # Change default search parameter key name.\n  # Default key name is :q\n  config.search_key = :query\n\n  # Raise errors if a query contains an unknown predicate or attribute.\n  # Default is true (do not raise error on unknown conditions).\n  config.ignore_unknown_conditions = false\n\n  # Globally display sort links without the order indicator arrow.\n  # Default is false (sort order indicators are displayed).\n  # This can also be configured individually in each sort link (see the README).\n  config.hide_sort_order_indicators = true\n\nend\n")),(0,i.kt)("h2",{id:"custom-search-parameter-key-name"},"Custom search parameter key name"),(0,i.kt)("p",null,"Sometimes there are situations when the default search parameter name cannot be used, for instance,\nif there are two searches on one page. Another name may be set using the ",(0,i.kt)("inlineCode",{parentName:"p"},"search_key")," option in the ",(0,i.kt)("inlineCode",{parentName:"p"},"ransack")," or ",(0,i.kt)("inlineCode",{parentName:"p"},"search")," methods in the controller, and in the ",(0,i.kt)("inlineCode",{parentName:"p"},"@search_form_for")," method in the view."),(0,i.kt)("h3",{id:"in-the-controller"},"In the controller"),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre",className:"language-ruby"},"@search = Log.ransack(params[:log_search], search_key: :log_search)\n# or\n@search = Log.search(params[:log_search], search_key: :log_search)\n")),(0,i.kt)("h3",{id:"in-the-view"},"In the view"),(0,i.kt)("pre",null,(0,i.kt)("code",{parentName:"pre",className:"language-erb"},"<%= f.search_form_for @search, as: :log_search %>\n<%= sort_link(@search) %>\n")))}f.isMDXComponent=!0}}]);