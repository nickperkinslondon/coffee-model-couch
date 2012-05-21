# coffee-model-couch
# extends coffee-model
# by Nick Perkins
# May 20, 2012

coffee_model = require '../coffee-model/coffee-model' # by me, also on github
couchdb = require 'couchdb-api' # by Dominic Barnes
expect = require 'expect.js'

say = console.log

is_a_database=(x)->
  # is this a Dominic Barnes "Database" object?
  keys = Object.keys(x)
  if keys.length == 3
    if x.server
      if x.server._url
        if x.server._url.hostname
          return true
  return false


class CouchModel extends coffee_model.Model
  #
  # subclass of "coffee-model".Model
  #  that knows how to Save and Retrieve itself
  #  to a CouchDB
  #

  constructor:(args...)->
    # args:
    #  any combination of:
    #
    # 1) db   ( Dominic Barnes "couchdb-api" Database )
    # 2) id   ( string )
    # 3) data ( object )
    #
    data = null
    id   = null

    for arg in args
      switch typeof arg

        when 'object'
          if is_a_database(arg)
            @set_db arg
          else
            data = arg

        when 'string'
          id = arg

        else
          throw new Error 'invalid arg to CouchModel.constructor'

    if not data
      data = {}

    if id
      data._id = id # a given ID overrides a data id

    # base class constructor takes data...
    super data

    @_unsaved_changes = true # until Save or Retrieve



  set:(key,val)->
    r = super key,val
    @_unsaved_changes = true
    return r


  get_id:->
    # the couchdb "_id" and "_rev" are stored on the data object
    # but are not "fields",
    # and so are not available to normal "get"/"set"
    @data._id # id may be undefined


  get_rev:->
    @data._rev # rev may be undefined


  set_db:(db)->
    if is_a_database(db)
      @db = db
    else
      console.dir db
      throw new Error "set_db() arg is not a Dominic Barnes Database"
    # a CouchModel must be assicated with a db
    # ( Dominic Barnes' "couchdb-api" class "Database" )


  save:(cb)->
    #
    # Unlike other "frameworks", I have decided NOT to add any
    #  extra meta-data to the saved document.
    #
    # I will assume that the calling code can keep track
    #  of what is what.
    #
    # This will allow other code to work with the same documents
    # ( play nice )
    #
    if not @db
      throw new Error "save() called without set_db()"
    if cb
      expect(cb).to.be.a('function')
    else
      # ok, no prob....(can still catch the 'save' event...)


    r = @validate()
    if not r.PASS
      return cb 'failed validation',null



    doc = @db.doc(@data)
    # Dominic Barnes "Document"
    expect(doc.body).to.be(@data)
    doc.save (err,resp)=>
      if not err
        @_unsaved_changes = false
      if cb
        cb(err,resp)
      @emit 'save'


  retrieve:(cb)->
    if cb
      expect(cb).to.be.a('function')
    if not @db
      throw new Error "retrieve() called without set_db()"

    id = @.get_id()
    if not id
      throw new Error "retrieve() called when id is not set"
    expect(id).to.be.a('string')

    doc = @db.doc({_id:id})
    # Dominic Barnes "Document"
    doc.get (err,resp)=>
      # "get" means retrieve from the database
      if not err
        @data = resp # will have new "_rev"
                     # could anything else be changed? maybe...
        @_unsaved_changes = false

        # call the user-supplied callback:
        if cb then cb(err,resp)

        @emit 'retrieve'


  has_unsaved_changes:->
    @_unsaved_changes

exports.CouchModel = CouchModel
