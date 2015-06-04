require 'yaml'
require 'erb'
require 'retryable'

require_relative 'posts'
require_relative 'taxonomies'
require_relative 'media'
require_relative 'comments'
require_relative 'options'
require_relative 'users'
require_relative 'xml_rpc_retryable'

module Rubypress

  class Client

    attr_reader :connection
    attr_accessor :port, :ssl_port, :host, :path, :username, :password, :use_ssl, :default_post_fields,
                  :debug, :http_user, :http_password, :retry_timeouts, :cookie

    def initialize(options = {})
      {
        :port => 80,
        :ssl_port => 443,
        :use_ssl => false,
        :host => nil,
        :path => '/xmlrpc.php',
        :username => nil,
        :password => nil,
        :default_post_fields => %w(post terms custom_fields),
        :debug => false,
        :http_user => nil,
        :http_password => nil,
        :retry_timeouts => false,
        :cookie => nil
      }.merge(options).each{ |opt| self.send("#{opt[0]}=", opt[1]) }
      self
    end

    def connection
      if @connection.nil?
        @connection = XMLRPC::Client.new(self.host, self.path, (self.use_ssl ? self.ssl_port : self.port),nil,nil,self.http_user,self.http_password,self.use_ssl,nil)
        @connection.http_header_extra = {'accept-encoding' => 'identity'}
        @connection.extend(XMLRPCRetryable) if retry_timeouts
        @connection.cookie = self.cookie unless self.cookie.nil?
      end
     
      @connection
    end

    def self.default
      use_ssl = ENV['WORDPRESS_USE_SSL'] == 'true'
      self.new(:host => ENV['WORDPRESS_HOST'], :port => ENV['WORDPRESS_PORT'].to_i, :username => ENV['WORDPRESS_USERNAME'], :password => ENV['WORDPRESS_PASSWORD'], :use_ssl => use_ssl)
    end

    def execute(method, options)
      args = []
      options_final = {
        :blog_id => 0,
        :username => self.username,
        :password => self.password
      }
      options_final.deep_merge!(options).each{|option| args.push(option[1]) if !option[1].nil?}
      method = "wp.#{method}" unless method.include?('.')
      if self.debug
        connection.set_debug
        server = self.connection.call(method, args)
        pp server
      else
        self.connection.call(method, args)
      end
    end

    include Posts
    include Taxonomies
    include Media
    include Comments
    include Options
    include Users

  end

end
