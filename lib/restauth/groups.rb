require 'restauth/common'
require 'restauth/users'

# Thrown when a group is not found.
class RestAuthGroupNotFound < RestAuthResourceNotFound
end

# Thrown when a group that is supposed to be created already exists.
class RestAuthGroupExists < RestAuthResourceConflict
end

# This class acts as a frontend for actions related to groups.
class RestAuthGroup < RestAuthResource
  attr_accessor :conn, :name

  ##
  # Factory method that creates a new group in RestAuth.
  def self.create( name, conn )
    resp = conn.post( '/groups/', { 'group' => name } )
    
    case resp.code.to_i
    when 201
      return RestAuthGroup.new( name, conn )
    when 409
      raise RestAuthGroupExists.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Factory method that gets an existing group from RestAuth.
  def self.get( name, conn )
    resp = conn.get( '/groups/'+name+'/' )
    
    case resp.code.to_i
    when 204
      return RestAuthGroup.new( name, conn )
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Factory method that gets all groups for this service known to
  # RestAuth.
  def self.get_all( conn, recursive = true, user = nil )
    params = {}
    if ( user )
      params['user'] = user
    end
    if ! recursive
      params['nonrecursive'] = 1
    end
    resp = conn.get( '/groups/', params )
    
    case resp.code.to_i
    when 200
      groups = Array.new()
      JSON.parse(resp.body).each { |groupname|
        groups.push( RestAuthGroup.new( groupname, conn ) )
      }
      return groups
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Constructor that initializes an object representing a group in RestAuth.
  # 
  # @param RestAuthConnection conn A connection to a RestAuth service.
  # @param string name The name of the new group.
  def initialize( name, conn )
    @conn = conn
    @name = name
  end

  ##
  # Get all members of this group.
  def get_members( recursive = true )
    params = {};
    if ( ! recursive )
      params['nonrecursive'] = 1
    end

    resp = conn.get( '/groups/'+name+'/users/', params )
    
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

  ##
  # Add a user to this group.
  def add_user( user )
    params = { 'user' => user.name }

    resp = conn.post( '/groups/'+name+'/users/', params)
    
    case resp.code.to_i
    when 204
      return
    when 404
      case resp.header['resource-type']
      when 'user'
        raise RestAuthUserNotFound.new( resp )
      when 'group'
        raise RestAuthGroupNotFound.new( resp )
      else
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end 
  end

  ##
  # Check if the named user is a member.
  def is_member( user, recursive = true )
    params = {}
    if ( ! recursive )
      params['nonrecursive'] = 1
    end
    
    resp = conn.get( '/groups/'+name+'/users/'+user.name+'/', params)

    case resp.code.to_i
    when 204
      return true
    when 404
      case resp.header['resource-type']
      when 'user'
        return false
      when 'group'
        raise RestAuthGroupNotFound.new( resp )
      else
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Delete this group.
  def remove()
    resp = conn.delete( '/groups/'+@name+'/' )
    
    case resp.code.to_i
    when 204
      return
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Remove the given user from the group.
  def remove_user( user )
    resp = conn.delete( '/groups/'+name+'/users/'+user.name+'/' )
    
    case resp.code.to_i
    when 204
      return
    when 404
      case resp.header['resource-type']
      when 'user'
        raise RestAuthUserNotFound.new( resp )
      when 'group'
        raise RestAuthGroupNotFound.new( resp )
      else
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Add a group to this group.
  def add_group( group )
    params = { 'group' => group.name }
    
    resp = conn.post('/groups/'+name+'/groups/', params)
    
    case resp.code.to_i
    when 204
      return
    when 404
      case resp.header['resource-type']
      when 'group'
        RestAuthGroupNotFound.new( resp )
      else
        RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # List all groups in this group.
  def get_groups()
    resp = conn.get( '/groups/'+name+'/groups/' )
    
    case resp.code.to_i
    when 200
      groups = Array.new()
      JSON.parse( resp.body ).each{ |groupname|
        groups.push(RestAuthGroup.new( conn, groupname ))
      }
      return groups
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Remove a group from this group.
  def remove_group( group )
    resp = conn.delete( '/groups/'+name+'/groups/'+group.name+'/' )
    
    case resp.code.to_i
    when 204
      return
    when 404
      raise RestAuthGroupNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end
end

