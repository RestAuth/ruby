require 'RestAuth/restauth_errors'
require 'RestAuth/restauth_common'
require 'json'

class RestAuthUserNotFound < RestAuthResourceNotFound
end

class RestAuthPropertyNotFound < RestAuthResourceNotFound
end

class RestAuthUserExists < RestAuthResourceConflict
end

class RestAuthPropertyExists < RestAuthResourceConflict
end

class RestAuthUser < RestAuthResource
  @@prefix = '/users/'
  attr_accessor :conn, :name

=begin
  Factory method that creates a new user in the RestAuth database and
  throws {@link RestAuthUserExists} if the user already exists.
=end
  def create( name, password, conn = @conn )
    params = { 'user' => name, 'password' => password }
    resp = conn.post( @@prefix, params )
    #resp = conn.post( '/users/', params )
    
    case resp.code.to_i
    when 201
      return RestAuthUser.new(conn, name)
    when 409
      raise RestAuthUserExists.new(resp)
    when 412
      raise RestAuthPreconditionFailed.new(resp)
    else
      raise RestAuthUnknownStatus.new(resp)
    end
  end

=begin
  Factory method that gets an existing user from RestAuth. This method
  verifies that the user exists and throws {@link RestAuthUserNotFound}
  if not.
=end
  def get( name = @name, conn = @conn )
    resp = conn.get( @@prefix+name+'/' )

    case resp.code.to_i
    when 204
      return RestAuthUser.new(conn, name)
    when 404
      raise RestAuthUserNotFound.new(resp)
    else
      raise RestAuthUnknownStatus.new(resp)
    end
  end

=begin
  Factory method that gets all users known to RestAuth.
=end
  def get_all( conn = @conn )
    resp = conn.get( @@prefix )

    case resp.code.to_i
    when 200
      response = Array.new
      JSON.parse(resp.body).each { |name|
        response.push( RestAuthUser.new(conn, name) )
      }
      return response
    else
      raise RestAuthUnknownStatus.new(resp)
    end
  end

=begin
  Constructor that initializes an object representing a user in
  RestAuth. 
  
  <b>Note:</b> The constructor does not verify if the user exists, use
  {@link get} or {@link get_all} if you wan't to be sure it exists.
=end
  def initialize( conn, name = nil )
    super
    @conn = conn
    @name = name
  end

=begin
  Set the password of this user.
  
  @param string $password The new password.
=end
  def set_password( password )
    resp = @conn.put(@@prefix+name+'/', { 'password' => password } )

    case resp.code.to_i
    when 204
      return
    when 404
      raise RestAuthUserNotFound.new(resp)
    when 412
      raise RestAuthPreconditionFailed.new(resp)
    else
      raise RestAuthUnknownStatus.new(resp)
    end
  end

=begin
  Verify the given password.
  
  The method does not throw an error if the user does not exist at all,
  it also returns false in this case.
=end
  def verify_password( password )
    resp = @conn.post(@@prefix+name+'/', { 'password' => password } )
    
    case resp.code.to_i
    when 204
      return true;
    when 404
      return false;
    else
      raise RestAuthUnknownStatus.new(resp)
    end
  end

=begin
  Delete this user.
=end
  def remove()
    resp = self._delete( name )
    
    case resp.getResponseCode()
      when 204
        return
      when 404
        raise RestAuthUserNotFound.new(resp)
      else
        raise RestAuthUnknownStatus.new(resp)
      end
  end

=begin
  Get all properties defined for this user.
  
  This method causes a single request to the RestAuth service and is
  a much better solution when fetching multiple properties.
#=end
  def get_properties()
    $url = "$this->name/props/";
    $resp = $this->_get( $url );
    
    switch ( $resp->getResponseCode() ) {
      case 200:
        $props = (array) json_decode( $resp->getBody() );
        return $props;
      case 404: throw new RestAuthUserNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end
  
=begin
  Set a property for this user. This method overwrites any previous
  entry.
#=end
  def set_property( name, value )
    $url = "$this->name/props/$name";
    $params = array( 'value' => $value );
    $resp = $this->_put( $url, $params );
    switch ( $resp->getResponseCode() ) {
      case 200: return $resp->getBody();
      case 201: return;
      case 404: throw new RestAuthUserNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Create a new property for this user. 
  
  This method fails if the property already existed. Use {@link
  set_property} if you do not care if the property already exists.
#=end
  def create_property( name, value )
    $url = "$this->name/props/";
    $params = array( 'prop' => $name, 'value' =>$value );
    $resp = $this->_post( $url, $params );
    switch ( $resp->getResponseCode() ) {
      case 201: return;
      case 404: throw new RestAuthUserNotFound( $resp );
      case 409: throw new RestAuthPropertyExists( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Get the given property for this user. 
  
  <b>Note:</b> Each call to this function causes an HTTP request to 
  the RestAuth service. If you want to get many properties, consider
  using {@link get_properties}.
#=end
  def get_property( name ) {
    $url = "$this->name/props/$name";
    $resp = $this->_get( $url );

    switch ( $resp->getResponseCode() ) {
      case 200:
        return json_decode( $resp->getBody() );
      case 404:
        switch ( $resp->getHeader( 'Resource-Type' ) ) {
          case 'User':
            throw new RestAuthUserNotFound( $resp );
          case 'Property':
            throw new RestAuthPropertyNotFound( $resp );
        }
        throw new RestAuthBadResponse( $resp,
          "Received 404 without Resource-Type header" );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  }

=begin
  Delete the named property.
#=end
  def del_property( name )
    url = "$this->name/props/#{name}";
    $resp = $this->_delete( $url );

    switch ( $resp->getResponseCode() ) {
      case 204: return;
      case 404: throw new RestAuthUserNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end
=end
end
