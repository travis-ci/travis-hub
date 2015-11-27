require 'database_cleaner'

DatabaseCleaner.strategy = :transaction

module Support
  module DatabaseCleaner
    extend ActiveSupport::Concern

    included do
      before      { ::DatabaseCleaner.start }
      after       { ::DatabaseCleaner.clean }
      after(:all) { ::DatabaseCleaner.clean_with :truncation }
    end
  end
end
