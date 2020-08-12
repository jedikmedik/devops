# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)

require 'prometheus/middleware/collector'
require 'prometheus/middleware/exporter'

# Prometheus metrics

# use Prometheus::Middleware::Collector, counter_label_builder: ->(env, code) do
#   {
#     method: env['REQUEST_METHOD'].upcase,
#     status: code,
#     path: env['REQUEST_PATH'].downcase.gsub(/[a-zA-Z0-9]{32}/, ":id")
#   }
# end, duration_label_builder: ->(env, code) do
#   {
#     method: env['REQUEST_METHOD'].upcase,
#     status: code,
#     path: env['REQUEST_PATH'].downcase.gsub(/[a-zA-Z0-9]{32}/, ":id")
#   }
# end

# use Prometheus::Middleware::Exporter

run Rails.application
