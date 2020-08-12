# frozen_string_literal: true

# Контроллер приложения
class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :null_session, if: Proc.new { |c| c.request.format == 'application/json' }

  before_action :set_locale

  $active_record_latency = 0
  $count_of_error = 0

  ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
    $active_record_latency = ActiveSupport::Notifications::Event.new(*args).duration
  end

  rescue_from ActiveRecord::RecordNotFound do
    render file: 'public/404.html', status: :not_found, layout: false
    $count_of_error += 1
  end

  rescue_from ActionView::MissingTemplate, with: :not_found

  rescue_from I18n::InvalidLocale, with: :locale_error

  def health_check
    begin
      Paste.last

      @last_db_query = "#{$active_record_latency.truncate(2)} ms"
      @db_status = 'ok'
    rescue PG::ConnectionBad => e
      @db_status = 'fail'
    end

    case params[:status]
    when 'simple'
      render json: { app: 'ok' }
    when 'advanced'
      render json: { app: 'ok', db: [postgres: @db_status] }
    when 'full'
      render json: { app: 'ok', db: [postgres: @db_status, last_db_query: @last_db_query, count_of_error: $count_of_error] }
    end
  end

  private

  def set_locale
    I18n.locale = params[:locale] || session[:locale] || http_accept_language.compatible_language_from(I18n.available_locales)
    session[:locale] = I18n.locale if session[:locale] != I18n.locale
  end

  def locale_error
    render plain: 'Unsupported locale. Available locale is ru/en'
  end
end
