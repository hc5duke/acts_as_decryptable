$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'acts_as_decryptable'
ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Decryptable }
