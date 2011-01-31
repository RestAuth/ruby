=begin
Code related to RestAuthGroup handling.

@package ruby-restauth
=end

=begin
imports required for the code here.
=end
require '/home/astra/git/repository/ruby/RestAuth/restauth_common.rb'
require '/home/astra/git/repository/ruby/RestAuth/restauth_users.rb'

=begin
Thrown when a group is not found.

@package ruby-restauth
=end
class RestAuthGroupNotFound < RestAuthResourceNotFound
end

=begin
Thrown when a group that is supposed to be created already exists.

@package ruby-restauth
=end
class RestAuthGroupExists < RestAuthResourceConflict
end

=begin
This class acts as a frontend for actions related to groups.

@package ruby-restauth
=end
class RestAuthGroup < RestAuthResource
  @@prefix = '/groups/'

=begin
  Factory method that creates a new group in RestAuth.
  
  @param RestAuthConnection $conn A connection to a RestAuth service.
  @param string $name The name of the new group.
  
  @param string $name The name of the new group
  @throws {@link RestAuthGroupExists} If the group already exists.
  @throws {@link RestAuthBadRequest} When the request body could not be
    parsed.
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param RestAuthConnection $conn A connection to a RestAuth service.
  @param string $name The name of the new group.
  
  @throws {@link RestAuthBadRequest} When the request body could not
    be parsed.
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param RestAuthConnection $conn A connection to a RestAuth service.
  @param string $user Limit the output to groups where the user with 
    this name is a member of.
  @param boolean $recursive Disable recursive group parsing.
  
  @throws {@link RestAuthBadRequest} When the request body could not be
    parsed.
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param boolean $recursive Set to false to disable recurive group
    parsing.
  @return array Array of {@link RestAuthUser users}.
  
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param RestAuthUser $user The user to add
  @param boolean $autocreate Set to false if you don't want to
    automatically create the group if it doesn't exist.
  
  @throws {@link RestAuthBadRequest} When the request body could not be
    parsed.
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param RestAuthUser $user The user in question.
  @param boolean $recursive Set to false to disable recurive group
    parsing.
  @return boolean true if the user is a member, false if not
  
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param RestAuthUser $user The user to remove
  
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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
  
  @param RestAuthGroup $group The group to add
  @param boolean $autocreate Set to false if you don't want to
    automatically create the group if it doesn't exist.
  
  @throws {@link RestAuthBadRequest} When the request body could not be
    parsed.
  @throws {@link RestAuthUnauthorized} When service authentication
    failed.
  @throws {@link RestAuthForbidden} When service authentication failed
    and authorization is not possible from this host.
  @throws {@link RestAuthInternalServerError} When the RestAuth service
    returns HTTP status code 500
  @throws {@link RestAuthUnknownStatus} If the response status is
    unknown.
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

