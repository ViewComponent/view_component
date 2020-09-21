# frozen_string_literal: true
require "sqlite3"

begin
  db = SQLite3::Database.open "../test.sqlite3"
  db.execute "CREATE TABLE IF NOT EXISTS ActionTextRichTexts(
    Id INTEGER PRIMARY KEY,
    name TEXT,
    body TEXT,
    record_type TEXT,
    record_id INTEGER,
    created_at TEXT,
    updated_at TEXT)"
rescue SQLite3::Exception => e
  puts "Exception occured"
  puts e
ensure
  db.close if db
end
