# 64 hex characters, e.g. `Lockbox.generate_key`. Required in production;
# losing it makes stored API keys unreadable.
Lockbox.master_key = ENV['LOCKBOX_MASTER_KEY'] || ('0' * 64 unless Rails.env.production?)
