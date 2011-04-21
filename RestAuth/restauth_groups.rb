require 'RestAuth/restauth_common'
require 'RestAuth/restauth_users'

# Thrown when a group is not found.
class RestAuthGroupNotFound < RestAuthResourceNotFound
end

# Thrown when a group that is supposed to be created already exists.
class RestAuthGroupExists < RestAuthResourceConflict
end

# This class acts as a frontend for actions related to groups.
class RestAuthGroup < RestAuthResource
  @@prefix = '/groups/'
  attr_accessor :conn, :name

=begin
  Factory method that creates a new group in RestAuth.
=end
  def create( name, conn = @conn )
    resp = conn.post( @@prefix, { 'group' => name } )
    
    case resp.code.to_i
    when 201
      return RestAuthGroup.new( conn, name )
    when 409
      raise RestAuthGroupExists.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Factory method that gets an existing group from RestAuth.
=end
  #def self.get( conn, name )
  def get( name = @name, conn = @conn )
    resp = conn.get( @@prefix+name+'/' )
    
    case resp.code.to_i
    when 204
      return RestAuthGroup.new( conn, name )
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Factory method that gets all groups for this service known to 
  RestAuth.
=end
  def get_all( recursive = true, user = nil, conn = @conn )
    params = {}
    if ( user )
      params['user'] = user
    end
    if ! recursive
      params['nonrecursive'] = 1
    end
    resp = conn.get( @@prefix, params )
    
    case resp.code.to_i
    when 200
      groups = Array.new()
      JSON.parse(resp.body).each { |groupname|
        groups.push( RestAuthGroup.new(conn, groupname) )
      }
      return groups
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Constructor that initializes an object representing a group in RestAuth.
  
  @param RestAuthConnection $conn A connection to a RestAuth service.
  @param string $name The name of the new group.
=end
  def initialize( conn, name = nil )
    super
    @conn = conn
    @name = name
  end

=begin
  Get all members of this group.
=end
  def get_members( recursive = true )
    params = {};
    if ( ! $recursive )
      params['nonrecursive'] = 1
    end

    resp = conn.get(@@prefix+name+'/users/', params)
    
    case resp.code.to_i
    when 200
      users = Array.new()
      JSON.parse(resp.body).each { |username|
        users.push(RestAuthUser.new(conn, username))
      }
      return users
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Add a user to this group.
=end

  def add_user( user, autocreate = true )
    params = { 'user' => user.name }
    if ( autocreate )
      params['autocreate'] = 1
    end

    resp = conn.post( @@prefix+name+'/users/', params)
    
    case resp.code.to_i
    when 204
      return
    when 404
      case resp.getHeader('Resource-Type')
      when 'User'
        raise RestAuthUserNotFound.new( resp )
      when 'Group'
        raise RestAuthGroupNotFound.new( resp )
      else
        # BUG TODO BUG
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end 
  end

=begin
  Check if the named user is a member.
=end
  def is_member( user, recursive = true )
    params = {}
    if ( ! recursive )
      params['nonrecursive'] = 1
    end
    
    resp = conn.get( @@prefix+name+'/users/'+user.name+'/', params)

    case resp.code.to_i
    when 204
      return true
    when 404
      case resp.getHeader( 'Resource-Type' )
      when 'User'
        return false
      when 'Group'
        raise RestAuthGroupNotFound.new( resp )
      else
        # BUG TODO BUG
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Delete this group.
=end
  def remove()
    resp = conn.delete( @@prefix+@name+'/' )
    
    case resp.code.to_i
    when 204
      return
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Remove the given user from the group.
=end
  def remove_user( user )
    resp = conn.delete( @@prefix+name+'/users/'+user.name+'/' )
    
    case resp.code.to_i
    when 204
      return
    when 404
      case resp.getHeader( 'Resource-Type' )
      when 'User'
        raise RestAuthUserNotFound.new( resp )
      when 'Group'
        raise RestAuthGroupNotFound.new( resp )
      else
        # BUG TODO BUG
        raise RestAuthBadResponse( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

=begin
  Add a group to this group.
#=end
  def add_group( $group, $autocreate = true )
    $params = array( 'group' => $group->name );
#    if ( $autocreate )
#      $params['autocreate'] = 1;
    
    $resp = $this->_post( $this->name . '/groups/', $params );
    switch ( $resp->getResponseCode() ) {
      case 204: return;
      case 404: switch ( $resp->getHeader( 'Resource-Type' ) ) {
        case 'Group': 
          throw new RestAuthGroupNotFound( $resp );
        default: 
          throw new RestAuthBadResponse( $resp,
            "Received 404 without Resource-Type header" );
        }
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

  def get_groups()
    $resp = $this->_get( $this->name . '/groups/' );
    switch ( $resp->getResponseCode() ) {
      case 200: 
        $users = array();
        foreach( json_decode( $resp->getBody() ) as $username ) {
          $users[] = new RestAuthUser( $this->conn, $username );
        }
        return $users;
      case 404: throw new RestAuthGroupNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

  def remove_group( $group )
    $resp = $this->_get( $this->name . '/groups/' . $group->name . '/' );
    switch ( $resp->getResponseCode() ) {
      case 204: return;
      case 404: throw new RestAuthGroupNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end
=end
end

