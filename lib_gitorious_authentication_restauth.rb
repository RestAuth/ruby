# encoding: utf-8
#--
#   Modification of gitorious-Ldap-authentication-patch of Marius Mathiesen <marius@shortcut.no>
#   Modified 2011 by David Kaufmann <astra@fsinf.at> for RestAuth
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'rubygems'
require 'restauth'
module Gitorious
  module Authentication
    class Restauth
      attr_accessor :logger
      
      def initialize(config)
        @logger = ::Rails.logger if !@logger && defined?(::Rails) && Rails.respond_to?(:logger)
        @logger = RAILS_DEFAULT_LOGGER if !@logger && defined?(RAILS_DEFAULT_LOGGER)
        @logger = Logger.new(STDOUT) if !@logger

        @host = config["host"] || "https://user:password@localhost:8000/"
        @verify_ssl = config["verify_ssl"] || true
        @autoregistration = config["autoregistration"] || true
        @fullname_attribute = config["fullname_attribute"]
        @email_attribute = config["email_attribute"]
        if @conn.nil?
          @conn = RestAuthConnection.new(url, @verify_ssl)
        end
      end

      # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
      def authenticate( login, password )
        logger.warn "RestAuth authenticating #{login}"
        begin
          remoteuser = RestAuthUser.get( login, @conn )
        rescue RestAuthUserNotFound
          logger.warn "RestAuth user #{login} not found."
          return nil
        end
        if ! remoteuser.verify_password( password )
          logger.warn "RestAuth user authentication for #{login} failed."
          return nil
        end
        u = User.find_by_login(login)
        if u
          sync_user(u, remoteuser)
          return u
        else
          logger.warn "RestAuth authentication succeeded for #{login} but no gitorious account exists."
          if @autoregistration
            return auto_register( login )
          else
            return nil
          end
        end
      end
      
      # Automatically registers a user by their username in gitorious. Returns the user or nil.
      def auto_register(username)
        logger.info "RestAuth auto-registering user #{username}"
        user = User.new

        user.login = username
        user.email = username+'@git.fsinf.at'
        user.crypted_password = 'restauth'
        user.salt = 'restauth'
        user.activated_at = Time.now.utc
        user.activation_code = nil
        user.terms_of_use = '1'
        user.aasm_state = 'terms_accepted'

        remoteuser = RestAuthUser.new( username, @conn )
        sync_user( user, remoteuser )
        
        user.save!
        user
      end

      # Updates a user from information in RestAuth-database
      def sync_user( user, remoteuser )
        if @full_name_attribute
          begin
            user.fullname = remoteuser.get_property( @fullname_attribute )
          rescue RestAuthPropertyNotFound => e
            if ! user.fullname.nil?
              user.fullname = remoteuser.create_property( @fullname_attribute, user.fullname )
            end
          end
        end
        if @email_attribute
          begin
            user.email = remoteuser.get_property( @email_attribute )
          rescue RestAuthPropertyNotFound => e
            if ! user.email.nil?
              user.email = remoteuser.create_property( @email_attribute, user.email )
            end
          end
        end
      end
    end
  end
end

