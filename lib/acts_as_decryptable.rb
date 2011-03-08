module ActiveRecord
  module Acts
    module Decryptable
      def self.included(base)
        base.extend(ClassMethods)
      end

      # class SomeModel < ActiveRecord::Base
      #   acts_as_decryptable :encrypt => [:name, :email], :key => "SOME_KEY", :show => '*' * 8
      # end
      #
      # some_model_object.name = "name"
      # some_model_object.save
      # some_model_object.name                        # => "encrypted name" or "********"
      # some_model_object.decrypted_name              # => "name"
      module ClassMethods
        def acts_as_decryptable(options)
          cattr_accessor :encrypted_columns
          configuration = { :encrypt => [] }
          configuration.update(options) if options.is_a?(Hash)
          raise "Valid key must be specified" unless configuration[:key]

          configuration[:encrypt].each do |field_name|
            class_eval <<-EOV
              def #{field_name}=(value)
                if value.present?
                  if value != #{configuration[:show].to_json}
                    self[:#{field_name}] = CGI::escape(SymmetricCrypto.encrypt(value, #{configuration[:key].to_json}))
                  end
                else
                  self[:#{field_name}] = nil
                end
              end

              def decrypt_#{field_name}
                value = self[:#{field_name}]
                if value.present?
                  SymmetricCrypto.decrypt(CGI::unescape(value), #{configuration[:key].to_json})
                else
                  nil
                end
              end
            EOV

            if configuration[:show]
              class_eval <<-EOV
                def #{field_name}
                  self[:#{field_name}].nil? ? nil : #{configuration[:show].to_json}
                end
              EOV
            end
          end
        end
      end

      class SymmetricCrypto
        def self.encrypt(text, key)
          aes(:encrypt, text, key)
        end

        def self.decrypt(crypted, key)
          aes(:decrypt, crypted, key)
        end

      private
        def self.aes(direction, message, key)
          cipher = OpenSSL::Cipher.new('AES256')
          direction == :encrypt ? cipher.encrypt : cipher.decrypt
          cipher.key = key
          cipher.update message
          cipher.final
        end
      end

    end
  end
end
