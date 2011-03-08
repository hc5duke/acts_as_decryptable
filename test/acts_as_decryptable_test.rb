require 'test/unit'

require 'rubygems'
gem 'activerecord', '>= 1.15.4.7794'
require 'active_record'
require 'cgi'

require "#{File.dirname(__FILE__)}/../init"

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")

def setup_db

  ActiveRecord::Schema.define(:version => 1) do
    create_table :mixins do |t|
      t.column :plaintext, :string
      t.column :encrypted, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
    end
  end
end

def teardown_db
  ActiveRecord::Base.connection.tables.each do |table|
    ActiveRecord::Base.connection.drop_table(table)
  end
end

class Mixin < ActiveRecord::Base
end

class DecryptableMixin < Mixin
  acts_as_decryptable :encrypt => [ :encrypted ], :key => 'a' * 32, :show => '*' * 8

  def self.table_name() "mixins" end
end

class DecryptTest < Test::Unit::TestCase

  def setup
    setup_db
    DecryptableMixin.create!
  end

  def teardown
    teardown_db
  end

  def test_encrypt
    decryptable = DecryptableMixin.first
    decryptable.plaintext = "text"
    decryptable.encrypted = "text"
    decryptable.save!

    assert_equal "text",  decryptable.plaintext
    assert_equal "text",  decryptable.decrypt_encrypted
    assert_equal "*" * 8, decryptable.encrypted

    decryptable.encrypted = "*" * 8
    decryptable.save
    assert_equal "text",  decryptable.decrypt_encrypted
    assert_equal "*" * 8, decryptable.encrypted
  end
end

