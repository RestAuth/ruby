##
# Template for RestAuthExceptions
class RestAuthException < Exception
  private_class_method :new
  def RestAuthException.inherited(subclass)
    subclass.instance_eval { public_class_method :new }
  end

  def initialize ( response )
    @message = response.body
  end
end

##
# Superclass for exceptions thrown when a resource queried is not found.
class RestAuthResourceNotFound < RestAuthException
  private_class_method :new
  def RestAuthResourceNotFound.inherited(subclass)
    subclass.instance_eval { public_class_method :new }
  end
  @code = 404
end

##
# Superclass of exceptions thrown when a resource is supposed to be created but
# already exists.
class RestAuthResourceConflict < RestAuthException
  private_class_method :new
  def RestAuthResourceConflict.inherited(subclass)
    subclass.instance_eval { public_class_method :new }
  end
  @code = 409
end

##
# Exception thrown when a response was unparsable.
class RestAuthBadResponse < RestAuthException
end

##
# Superclass for service-related errors.
class RestAuthInternalException < RestAuthException
end

##
# Thrown when the RestAuth service cannot parse the HTTP request. On a protocol
# level, this corresponds to a HTTP status code 400.
class RestAuthBadRequest < RestAuthInternalException
  @code = 400
end

##
# Thrown when the RestAuth service suffers an internal error. On a protocol
# level, this corresponds to a HTTP status code 500.
class RestAuthInternalServerError < RestAuthInternalException
  @code = 500
end

##
# Thrown when an unknown HTTP status code is encountered. This should never
# really happen and usually indicates a bug in the library.
class RestAuthUnknownStatus < RestAuthInternalException
  def initialize ( response )
    super
    @code = response.code.to_i
  end
end

##
# Thrown when you send unacceptable data to the RestAuth service, i.e. a
# password that is too short.
class RestAuthPreconditionFailed < RestAuthException
  @code = 412
end

##
# Thrown when the user/password does not match the registered service.
# 
# On a protocol level, this corresponds to the HTTP status code 401.
class RestAuthUnauthorized < RestAuthException
  @code = 401
end

class RestAuthNotAcceptable < RestAuthInternalException
 @code = 406
end

class RestAuthUnsupportedMediaType < RestAuthInternalException
 @code = 415
end
