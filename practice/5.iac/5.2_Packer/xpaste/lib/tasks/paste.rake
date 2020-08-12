namespace :paste do
  task delete_expired: :environment do
    Paste.where('will_be_deleted_at <= ?', Time.now).delete_all
  end
end
