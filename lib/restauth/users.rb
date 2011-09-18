require 'restauth/errors'
require 'restauth/common'
require 'json'

##
# Exception thrown when a user could not be found. 
class RestAuthUserNotFound < RestAuthResourceNotFound
end

##
# Exception thrown when a property could not be found. 
class RestAuthPropertyNotFound < RestAuthResourceNotFound
end

##
# Exception thrown when trying to create an already existing user. 
class RestAuthUserExists < RestAuthResourceConflict
end

##
# Exception thrown when trying to create an already existing property. 
class RestAuthPropertyExists < RestAuthResourceConflict
end

##
# This class acts as a frontend for actions related to users. 
class RestAuthUser < RestAuthResource
  attr_accessor :conn, :name

  ##
  # Factory method that creates a new user in the RestAuth database and
  # throws RestAuthUserExists if the user already exists.
  def self.create( name, password, conn )
    params = { 'user' => name, 'password' => password }
    resp = conn.post( '/users/', params )
    
    case resp.code.to_i
    when 201
      return RestAuthUser.new( name, conn )
    when 409
      raise RestAuthUserExists.new( resp )
    when 412
      raise RestAuthPreconditionFailed.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Factory method that gets an existing user from RestAuth. This method
  # verifies that the user exists and throws RestAuthUserNotFound
  # if not.
  def self.get( name, conn )
    resp = conn.get( '/users/'+name+'/' )

    case resp.code.to_i
    when 204
      return RestAuthUser.new( name, conn )
    when 404
      raise RestAuthUserNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Factory method that gets all users known to RestAuth.
  def self.get_all( conn )
    resp = conn.get( '/users/' )

    case resp.code.to_i
    when 200
      response = Array.new
      JSON.parse(resp.body).each { |name|
        response.push( RestAuthUser.new( name, conn ) )
      }
      return response
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Constructor that initializes an object representing a user in
  # RestAuth. 
  #
  #<b>Note:</b> The constructor does not verify if the user exists, use
  # get or get_all if you wan't to be sure it exists.
  def initialize( name, conn )
    @conn = conn
    # RestAuth >> Server: Bug #6
    # username owning properties is case-sensitive
    @name = name.downcase  
  end

  ##
  # Set the password of this user.
  # 
  # @param string $password The new password.
  def set_password( password )
    resp = conn.put('/users/'+name+'/', { 'password' => password } )

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

  ##
  # Verify the given password.
  # 
  # The method does not throw an error if the user does not exist at all,
  # it also returns false in this case.
  def verify_password( password )
    resp = conn.post('/users/'+name+'/', { 'password' => password } )
    
    case resp.code.to_i
    when 204
      return true;
    when 404
      return false;
    else
      raise RestAuthUnknownStatus.new(resp)
    end
  end

  ##
  # Delete this user.
  def remove()
    resp = conn.delete('/users/'+name+'/' )
    
    case resp.code.to_i
      when 204
        return
      when 404
        raise RestAuthUserNotFound.new(resp)
      else
        raise RestAuthUnknownStatus.new(resp)
      end
  end

  ##
  # Get all properties defined for this user.
  # 
  # This method causes a single request to the RestAuth service and is
  # a much better solution when fetching multiple properties.
  def get_properties()
    resp = conn.get('/users/'+name+'/props/')
    
    case resp.code.to_i
    when 200
      return JSON.parse(resp.body)
    when 404
      raise RestAuthUserNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( rest )
    end
  end
  
  ##
  # Set a property for this user. This method overwrites any previous
  # entry.
  def set_property( propname, value )
    params = { 'value' => value }
    resp = conn.put('/users/'+name+'/props/'+propname+'/', params)
    
    case resp.code.to_i
    when 200
      return JSON.parse( resp.body )
    when 201
      return
    when 404
      raise RestAuthResourceNotFound.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Create a new property for this user. 
  # 
  # This method fails if the property already existed. Use set_property
  # if you do not care if the property already exists.
  def create_property( propname, value )
    params = { 'prop' => propname, 'value' => value }
    resp = conn.post( '/users/'+name+'/props/', params )
    
    case resp.code.to_i
    when 201
      return
    when 404
      raise RestAuthUserNotFound.new( resp )
    when 409
      raise RestAuthPropertyExists.new( resp )
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Get the given property for this user. 
  # 
  # <b>Note:</b> Each call to this function causes an HTTP request to 
  # the RestAuth service. If you want to get many properties, consider
  # using get_properties.
  def get_property( propname )
    resp = conn.get('/users/'+name+'/props/'+propname+'/')
    
    case resp.code.to_i
    when 200
      return JSON.parse( resp.body )
    when 404
      case resp.header['resource-type']
      when 'user'
        raise RestAuthUserNotFound.new( resp )
      when 'property'
        raise RestAuthPropertyNotFound.new( resp )
      else
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end

  ##
  # Delete the named property.
  def del_property( propname )
    resp = conn.delete('/users/'+name+'/props/'+propname+'/')
    
    case resp.code.to_i
    when 204
      return
    when 404
      case resp.header['resource-type']
      when 'user'
        raise RestAuthUserNotFound.new( resp )
      when 'property'
        raise RestAuthPropertyNotFound.new( resp )
      else
        raise RestAuthBadResponse.new( resp, "Received 404 without Resource-Type header" )
      end
    else
      raise RestAuthUnknownStatus.new( resp )
    end
  end
end
