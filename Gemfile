source "https://rubygems.org"

# Hello! This is where you manage which Jekyll version is used to run.
# When you want to use a different version, change it below, save the
# file and run `bundle install`. Run Jekyll with `bundle exec`, like so:
#
#     bundle exec jekyll serve
#
# This will help ensure the proper Jekyll version is running.
# Happy Jekylling!
gem "jekyll", '~>3.9', '>= 3.9.5'

# IMPORTANT: The followign gem is used to compile math formulas to
# KaTeX during site building.
#
# There are a couple of things to know about this gem:
# *  It is not supported on GitHub Pages. 
#    You have to build the site on your machine before uploading to GitHub,
#    or use a more permissive cloud building tool such as Netlify.
# *  You need some kind of JavaScript runtime on your machine.
#    Usually installing NodeJS will suffice. 
#    For details, see <https://github.com/kramdown/math-katex#documentation>
#
# If you're using the MathJax math engine instead, free to remove the line below:
gem "kramdown-math-katex"

# A JavaScript runtime for ruby that helps with running the katex gem above.
gem "duktape"

# Fixes `jekyll serve` in ruby 3
gem "webrick"
gem 'faraday-retry'
gem "github-pages-health-check", '~>1.18', '>= 1.18.2'
gem "github-pages",              '~>231',  '>= 231'

group :jekyll_plugins do
  gem "html-pipeline",                '~>2.14',  '>= 2.14.3'
  gem "jekyll-avatar",                '~>0.8',   '>= 0.8.0'
  gem "jekyll-coffeescript",          '~>1.2',   '>= 1.2.2'
  gem "jekyll-commonmark-ghpages",    '~>0.4',   '>= 0.4.0'
  gem "jekyll-default-layout",        '~>0.1',   '>= 0.1.5'
  gem "jekyll-feed",                  '~>0.17',  '>= 0.17.0'
  gem "jekyll-gist",                  '~>1.5',   '>= 1.5.0'
  gem "jekyll-github-metadata",       '~>2.16',  '>= 2.16.1'
  gem "jekyll-include-cache",         '~>0.2',   '>= 0.2.1'
  gem "jekyll-mentions",              '~>1.6',   '>= 1.6.0'
  gem "jekyll-optional-front-matter", '~>0.3',   '>= 0.3.2'
  gem "jekyll-paginate",              '~>1.1',   '>= 1.1.0'
  gem "jekyll-readme-index",          '~>0.3',   '>= 0.3.0'
  gem "jekyll-redirect-from",         '~>0.16',  '>= 0.16.0'
  gem "jekyll-relative-links",        '~>0.6',   '>= 0.6.1'
  gem "jekyll-remote-theme",          '~>0.4',   '>= 0.4.3'
  gem "jekyll-sass-converter",        '~>1.5',   '>= 1.5.2'
  gem "jekyll-seo-tag",               '~>2.8',   '>= 2.8.0'
  gem "jekyll-sitemap",               '~>1.4',   '>= 1.4.0'
  gem "jekyll-swiss",                 '~>1.0',   '>= 1.0.0'
  gem "jekyll-theme-architect",       '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-cayman",          '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-dinky",           '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-hydejack",        '~>9.1',   '>= 9.1.6'
  gem "jekyll-theme-hacker",          '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-leap-day",        '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-merlot",          '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-midnight",        '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-minimal",         '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-modernist",       '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-slate",           '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-primer",          '~>0.6',   '>= 0.6.0' 
  gem "jekyll-theme-tactile",         '~>0.2',   '>= 0.2.0'
  gem "jekyll-theme-time-machine",    '~>0.2',   '>= 0.2.0'
  gem "jekyll-titles-from-headings",  '~>0.5',   '>= 0.5.3'
  gem "jemoji",                       '~>0.13',  '>= 0.13.0'
  gem "kramdown-parser-gfm",          '~>1.1',   '>= 1.1.0'
  gem "kramdown",                     '~>2.4',   '>= 2.4.0'
  gem "liquid",                       '~>4.0',   '>= 4.0.4'
  gem "minima",                       '~>2.5',   '>= 2.5.1'
  gem "nokogiri",                     '~>1.15',  '>= 1.15.5'
  gem "rouge",                        '~>3.30',  '>= 3.30.0'
  gem "safe_yaml",                    '~>1.0',   '>= 1.0.5'
  gem "sass",                         '~>3.7',   '>= 3.7.4'

  # Non-Github Pages plugins:
  gem "jekyll-last-modified-at"
  gem "jekyll-compose"
end

gem 'wdm' if Gem.win_platform?
gem "tzinfo-data" if Gem.win_platform?
