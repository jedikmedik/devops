# frozen_string_literal: true

# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# remove bash -l -c (rvm)
set :job_template, nil

# output to stdout
job_type :rake, 'cd :path && :environment_variable=:environment bundle exec rake :task > /proc/1/fd/1 2>/proc/1/fd/2'
job_type :runner, "cd :path && bin/rails runner -e :environment ':task' > /proc/1/fd/1 2>/proc/1/fd/2"

every 1.day, at: '0:07' do
  rake 'paste:delete_expired'
end
