
source 'https://rubygems.org'
ruby '2.2.3'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails'

# Use postgresql as the database for Active Record
gem 'pg'

gem 'activerecord-postgis-adapter'
gem 'rails_admin', '~> 1.0'
gem 'dotenv-rails'

gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'coffee-rails', '~> 4.1.0'
gem 'jquery-rails'
gem 'turbolinks'
gem 'jbuilder', '~> 2.0'

gem "paperclip", "~> 5.1.0"

gem 'therubyracer', platforms: :ruby

# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# per Authorial London project
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-rails'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end
