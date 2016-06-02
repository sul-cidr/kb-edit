# config valid only for current version of Capistrano
lock '3.5.0'

set :application, 'kindred-britain-edit'
set :repo_url, 'https://github.com/sul-cidr/kb-edit.git'
set :deploy_host, ENV['CAP_DEPLOY_HOST']
set :user, ENV['CAP_USER']
set :deploy_to, ENV['CAP_DEPLOY_TO']
set :bundle_without, nil

server "#{fetch(:deploy_host)}.stanford.edu", user: fetch(:user), roles: %w{web db app}
Capistrano::OneTimeKey.generate_one_time_key!

# Default branch is :master
ask :branch, `git rev-parse --abbrev-ref HEAD`.chomp

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :airbrussh.
# set :format, :airbrussh

# You can configure the Airbrussh format using :format_options.
# These are the defaults.
# set :format_options, command_output: true, log_file: 'log/capistrano.log', color: :auto, truncate: :auto

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, fetch(:linked_files, []).push(
  'config/secrets.yml',
  'config/database.yml',
  '.env'
)

# Default value for linked_dirs is []
 set :linked_dirs, fetch(:linked_dirs, []).push(
   'log',
   'public/system',
   'tmp/pids',
   'tmp/cache',
   'tmp/sockets',
   'data',
 )

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 2

namespace :deploy do

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

end
