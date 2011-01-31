require "base64"
require "net/http"
Net::HTTP.version_1_2

class RestAuthConnection
  @@connection = nil
  
  def initialize ( host, user, password, use_cookies=true )
    @host = host.gsub(/[#{'\/'}]+$/, '')
    @user = user
    @password = password
    self.set_credentials( user, password )
    @use_cookies = use_cookies
    puts 'Initialized RestAuthConnection'
  end
  
  def get_connection( host=@host, user=@user, password=@password, use_cookies=@use_cookies )
    if ! defined?(@@connection)
      @@connection = RestAuthConnection.new( host, user, password, use_cookies )
    end
    puts 'RestAuthConnection::get_connection called'
    return @@connection
  end
  
  def set_credentials( user, password )
    @cookie = false # invalidate any old cookie
    @user = user
    @password = password
    @auth_header = Base64.encode64( user + ':' + password )
    puts 'RestAuthConnection::set_credentials called'
  end
  
  def use_cookie()
    if ! ( @cookie && @use_cookies )
      puts 'RestAuthConnection::use_cookie called (returning false 1)'
      return false
    end
    
    now = Time.new();
    if ( @cookie.expires < now )
      puts 'RestAuthConnection::use_cookie called (returning false 2)'
      return false
    end
    
    if @cookie.cookies.include?(:'Max-Age')
      max_age = @cookie.cookies['Max-Age']
      if ( @cookie_stamp + max_age < now )
        puts 'RestAuthConnection::use_cookie called (returning false 3)'
        return false
      end
    end
    
    puts 'RestAuthConnection::use_cookie called (returning true)'
    return true
  end

  def send( request )
    # add headers present with all methods
    
    headers = { 'Accept' => 'application/json' }
    
    if self.use_cookie()
      headers['Cookie'] = 'sessionid=' + @cookie.cookies['sessionid']
    else
      headers['Authorization'] = 'Basic ' + @auth_header
    end
    headers.each { |key,value|
      request.add_field( key, value )
    }
    
    uri = URI.parse( @host )
    puts 'Creating new Net::HTTP ('+uri.host+', '+uri.port.to_s+')'
    http = Net::HTTP.new(uri.host, uri.port)
    puts 'http.request(request)'
    response = http.request( request )
    puts 'Got CODE: '+response.code
    if ! response.body.nil?
      puts 'Got BODY: '+response.body
    end

    # handle cookie
    #if @response_headers.include?(:'Set-Cookie')
      # TODO cookies later!
      # : invalid code!
      #@cookie = http_parse_cookie( @response_headers['Set-Cookie'] )
    #  @cookie_stamp = Time.new()
    #end

    puts 'RestAuthConnection::send called (before case)'
    # handle error status codes
    case response.code
      when 401
      raise new RestAuthUnauthorized( response )
      when 406
      raise new RestAuthNotAcceptable( response )
      when 500
      raise new RestAuthInternalServerError( response )
    end

    puts 'RestAuthConnection::send called'
    return response
  end

  def get( urlpath, params = {}, headers = {} )
    headers['Content-Type'] = 'application/json'
    
    ## will fix later
    #url = @host + self.sanitize_url( url )
    #uri = URI.parse(url)
    
    puts 'creating new Net::HTTP::Get request -> '+urlpath
    request = Net::HTTP::Get.new( urlpath, headers )
    puts 'sending created request.'
    response = self.send( request )
    
    puts 'RestAuthConnection::get called (before case)'
    case response.code
      when 400
        raise RestAuthBadRequest.new( response )
      when 411
        raise Exception.new("Request did not send a Content-Length header!" )
      when 415
        raise RestAuthUnsupportedMediaType.new( response )
    end
    
    puts 'RestAuthConnection::get called'
    return response;
  end
end

class RestAuthResource
  @prefix = nil
  
  private_class_method :new
  def RestAuthResource.inherited(subclass)
    subclass.instance_eval { public_class_method :new }
  end
  
  def _get( url, params = {}, headers = {} )
    url = @prefix + url
    puts 'RestAuthResource::_get called'
    return @conn.get( url, params, headers )
  end
end
