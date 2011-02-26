Net::HTTP.version_1_2

class RestAuthConnection
  @@connection = nil
  
  def initialize ( host, user, password )
    @host = host.gsub(/[#{'\/'}]+$/, '')
    @user = user
    @password = password
    self.set_credentials( user, password )
    puts 'Initialized RestAuthConnection'
  end
  
  def get_connection( host=@host, user=@user, password=@password )
    if ! defined?(@@connection)
      @@connection = RestAuthConnection.new( host, user, password )
    end
    puts 'RestAuthConnection::get_connection called'
    return @@connection
  end
  
  def set_credentials( user, password )
    @user = user
    @password = password
    @auth_header = 'Basic ' + Base64.encode64( user + ':' + password )
    puts 'RestAuthConnection::set_credentials called'
  end
  
  def send( request )
    # add headers present with all methods
    
    headers = { 'Accept' => 'application/json', 'Authorization' => @auth_header }
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

  # params = querystring; {Ruby: dict -> querystring - method??}
  # an den server werden *nur* key->value - pairs gesendet.
  # zurückkommen können auch str & str-array
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
  @@prefix = nil
  @conn = nil
 
# improvise abstract classes
  private_class_method :new
  def RestAuthResource.inherited(subclass)
    subclass.instance_eval { public_class_method :new }
  end


  def _get( url, params = {}, headers = {} )
    url = @@prefix + url
    puts 'RestAuthResource::_get called'
    return @conn.get( url, params, headers )
  end
end
