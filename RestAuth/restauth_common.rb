require "base64"
require "net/http"
require "json"
Net::HTTP.version_1_2

class RestAuthConnection
  @@connection = nil
  
  def initialize ( host, user, password )
    @host = host.gsub(/[#{'\/'}]+$/, '')
    @user = user
    @password = password
    self.set_credentials( user, password )
    puts 'DEBUG Initialized RestAuthConnection'
  end
  
  def get_connection( host=@host, user=@user, password=@password )
    if ! defined?(@@connection)
      @@connection = RestAuthConnection.new( host, user, password )
    end
    puts 'CALLINFO RestAuthConnection::get_connection called'
    return @@connection
  end
  
  def set_credentials( user, password )
    @user = user
    @password = password
    @auth_header = 'Basic ' + Base64.encode64( user + ':' + password ).strip
    puts 'CALLINFO RestAuthConnection::set_credentials called'
  end
  
  def send( request )
    # add headers present with all methods
    
    headers = { 'Accept' => 'application/json', 'Authorization' => @auth_header }
    headers.each { |key,value|
      request.add_field( key, value )
    }
    
    uri = URI.parse( @host )
    puts 'HTTPCALL Net::HTTP.new('+uri.host+', '+uri.port.to_s+')'
    http = Net::HTTP.new(uri.host, uri.port)
    response = http.request( request )
    puts 'RESPONSE code: '+response.code
    if ! response.body.nil?
      puts 'RESPONSE body: '+response.body
    end

    # handle error status codes
    case response.code.to_i
    when 401
      raise RestAuthUnauthorized.new( response )
    when 406
      raise RestAuthNotAcceptable.new( response )
    when 500
      raise RestAuthInternalServerError.new( response )
    end

    return response
  end

  # params = querystring; {Ruby: dict -> querystring - method??}
  # an den server werden *nur* key->value - pairs gesendet.
  # zurückkommen können auch str & str-array
  def get( urlpath, params = {}, headers = {} )
    headers['Content-Type'] = 'application/json'
    
    ## will fix later
    #url = @host + self.sanitize_url( url )
    #uri = URI.parse(url)
    
    puts 'REQUEST creating new Net::HTTP::Get request -> '+urlpath
    request = Net::HTTP::Get.new( urlpath, headers )
    response = self.send( request )
    
    case response.code.to_i
      when 400
        raise RestAuthBadRequest.new( response )
      when 411
        raise Exception.new("Request did not send a Content-Length header!" )
      when 415
        raise RestAuthUnsupportedMediaType.new( response )
    end
    return response;
  end
  
  # params = querystring; {Ruby: dict -> querystring - method??}
  # an den server werden *nur* key->value - pairs gesendet.
  # zurückkommen können auch str & str-array
  def post( urlpath, params, headers = {} )
    headers['Content-Type'] = 'application/json'
    
    ## will fix later
    #url = @host + self.sanitize_url( url )
    #uri = URI.parse(url)
    
    puts 'REQUEST creating new Net::HTTP::Post request -> '+urlpath
    request = Net::HTTP::Post.new( urlpath, headers )
    request.body = params.to_json
    response = self.send( request )
    
    case response.code.to_i
      when 400
        raise RestAuthBadRequest.new( response )
      when 411
        raise Exception.new("Request did not send a Content-Length header!" )
      when 415
        raise RestAuthUnsupportedMediaType.new( response )
    end
    return response;
  end
  
  # params = querystring; {Ruby: dict -> querystring - method??}
  # an den server werden *nur* key->value - pairs gesendet.
  # zurückkommen können auch str & str-array
  def put( urlpath, params, headers = {} )
    headers['Content-Type'] = 'application/json'
    
    ## will fix later
    #url = @host + self.sanitize_url( url )
    #uri = URI.parse(url)
    
    # TODO fix (currently copied from GET)
    puts 'REQUEST creating new Net::HTTP::Put request -> '+urlpath
    request = Net::HTTP::Put.new( urlpath, headers )
    request.body = params.to_json
    response = self.send( request )
    
    case response.code.to_i
      when 400
        raise RestAuthBadRequest.new( response )
      when 411
        raise Exception.new("Request did not send a Content-Length header!" )
      when 415
        raise RestAuthUnsupportedMediaType.new( response )
    end
    return response;
  end
  
  # params = querystring; {Ruby: dict -> querystring - method??}
  # an den server werden *nur* key->value - pairs gesendet.
  # zurückkommen können auch str & str-array
  def delete( urlpath, headers = {} )
    ## will fix later
    #url = @host + self.sanitize_url( url )
    #uri = URI.parse(url)
    
    # TODO fix (currently copied from GET)
    puts 'REQUEST creating new Net::HTTP::Delete request -> '+urlpath
    request = Net::HTTP::Delete.new( urlpath, headers )
    response = self.send( request )
    
    case response.code.to_i
      when 400
        raise RestAuthBadRequest.new( response )
      when 411
        raise Exception.new("Request did not send a Content-Length header!" )
      when 415
        raise RestAuthUnsupportedMediaType.new( response )
    end
    return response;
  end
  
  def sanitize_url( url )
    # TODO copied from php
    url = url.chomp("\/") + "/"
    
    parts = array()
    explode('/', url).each { |part|
      part_encoded = rawurlencode( part )
      parts[] = part_encoded
    }
    url = implode( '/', parts )
    return url;
  end
end

class RestAuthResource
  @conn = nil
 
# improvise abstract classes
  private_class_method :new
  def RestAuthResource.inherited(subclass)
    subclass.instance_eval { public_class_method :new }
  end

  def _get( prefix, url, params = {}, headers = {} )
    puts 'CALLINFO RestAuthResource::_get called'
    return @conn.get( prefix + url, params, headers )
  end
  
  def _post( prefix, url, params = {}, headers = {} )
    puts 'CALLINFO RestAuthResource::_post called'
    return @conn.post( prefix + url, params, headers )
  end
  
  def _put( prefix, url, params = {}, headers = {} )
    puts 'CALLINFO RestAuthResource::_put called'
    return @conn.put( prefix + url, params, headers )
  end
  
  def _delete( prefix, url, headers = {} )
    puts 'CALLINFO RestAuthResource::_delete called'
    return @conn.delete( prefix + url, headers )
  end
end
