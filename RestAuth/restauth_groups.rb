require '/home/astra/git/restauth/ruby/RestAuth/restauth_common.rb'
require '/home/astra/git/restauth/ruby/RestAuth/restauth_users.rb'

# Thrown when a group is not found.
class RestAuthGroupNotFound < RestAuthResourceNotFound
end

# Thrown when a group that is supposed to be created already exists.
class RestAuthGroupExists < RestAuthResourceConflict
end

# This class acts as a frontend for actions related to groups.
class RestAuthGroup < RestAuthResource
  @@prefix = '/groups/'

=begin
# Factory method that creates a new group in RestAuth.
#=end
  def create( conn, name )
    $resp = $conn->post( '/groups/', array( 'group' => $name ) );
    switch ( $resp->getResponseCode() ) {
      case 201: return new RestAuthGroup( $conn, $name );
      case 409: throw new RestAuthGroupExists( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Factory method that gets an existing user from RestAuth.
#=end
  def get( conn, name )
    $resp = $conn->get( '/groups/' . $name . '/' );
    switch ( $resp->getResponseCode() ) {
      case 204: return new RestAuthGroup( $conn, $name );
      case 404: throw new RestAuthGroupNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Factory method that gets all groups for this service known to 
  RestAuth.
#=end
  def get_all( $conn, $user=NULL, $recursive=true )
    $params = array();
    if ( $user )
      $params['user'] = $user;
#    if ( ! $recursive )
#      $params['nonrecursive'] = 1;
  
    $resp = $conn->get( '/groups/', $params );
    switch ( $resp->getResponseCode() ) {
      case 200: 
        $groups = array();
        foreach ( json_decode( $resp->getBody() ) as $groupname ) {
          $groups[] = new RestAuthGroup( $conn, $groupname );
        }
        return $groups;
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Constructor that initializes an object representing a group in RestAuth.
  
  @param RestAuthConnection $conn A connection to a RestAuth service.
  @param string $name The name of the new group.
#=end
  def __construct( $conn, $name )
    $this->prefix = '/groups/';
    $this->conn = $conn;
    $this->name = $name;
  end

=begin
  Get all members of this group.
#=end
  def get_members( $recursive = true )
    $params = array();
#    if ( ! $recursive )
#      $params['nonrecursive'] = 1;

    $resp = $this->_get( $this->name . '/users/', $params );
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

=begin
  Add a user to this group.
#=end
  def add_user( $user, $autocreate = true )
    $params = array( 'user' => $user->name );
#    if ( $autocreate )
#      $params['autocreate'] = 1;

    $resp = $this->_post( $this->name . '/users/', $params );
    switch ( $resp->getResponseCode() ) {
      case 204: return;
      case 404: switch ( $resp->getHeader( 'Resource-Type' ) ) {
        case 'User':
          throw new RestAuthUserNotFound( $resp );
        case 'Group': 
          throw new RestAuthGroupNotFound( $resp );
        default: 
          throw new RestAuthBadResponse( $resp,
            "Received 404 without Resource-Type header" );
        }
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Check if the named user is a member.
#=end
  def is_member( $user, $recursive = true )
    $params = array();
    if ( ! $recursive )
      $params['nonrecursive'] = 1;

    $url = $this->name . '/users/' . $user->name;
    $resp = $this->_get( $url, $params );

    switch ( $resp->getResponseCode() ) {
      case 204: return true;
      case 404:
        switch ( $resp->getHeader( 'Resource-Type' ) ) {
          case 'User':
            return false;
          case 'Group': 
            throw new RestAuthGroupNotFound( $resp );
          default: 
            throw new RestAuthBadResponse( $resp,
              "Received 404 without Resource-Type header" );
        }
      default:
        throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Delete this group.
#=end
  def remove()
    $resp = $this->_delete( $this->name );
    switch ( $resp->getResponseCode() ) {
      case 204: return;
      case 404: throw new RestAuthGroupNotFound( $resp );
      default: throw new RestAuthUnknownStatus( $resp );
    }
  end

=begin
  Remove the given user from the group.
#=end
  def remove_user( $user )
    $url = $this->name . '/users/' . $user->name;
    $resp = $this->_delete( $url );

    switch ( $resp->getResponseCode() ) {
      case 204: return;
      case 404:
        switch ( $resp->getHeader( 'Resource-Type' ) ) {
          case 'User':
            throw new RestAuthUserNotFound( $resp );
          case 'Group': 
            throw new RestAuthGroupNotFound( $resp );
          default: 
            throw new RestAuthBadResponse( $resp,
              "Received 404 without Resource-Type header" );
        }
      default:
        throw new RestAuthUnknownStatus( $resp );
    }
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

