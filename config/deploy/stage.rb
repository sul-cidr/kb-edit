server 'cidr-kindred-britain-edit-stage.stanford.edu', user: fetch(:user), roles: %w{web db app}
Capistrano::OneTimeKey.generate_one_time_key!
