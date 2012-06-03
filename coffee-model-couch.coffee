# coffee-model-couch
# extends coffee-model
# by Nick Perkins
# started May 20, 2012


coffee_model = require '../coffee-model/coffee-model' # by me, also on github
couchdb = require 'couchdb-api' # by Dominic Barnes
expect = require 'expect.js'

json = JSON.stringify

say = console.log
dir = console.dir

show = (x)->
  say json(x)

check = (err)->
  if err
    throw new Error JSON.stringify(err)

is_a_database=(x)->
  # is this a Dominic Barnes "Database" object?
  keys = Object.keys(x)
  if keys.length == 3
    if x.server
      if x.server._url
        if x.server._url.hostname
          return true
  return false

is_date=(x)->
  return (x instanceof Date)
  # could fail on browser if cross-window or something?

is_date_array=(x)->
  if typeof x is 'object'
    if x.length
      if x.length == 3
        year = x[0]
        if typeof year is 'number'
          if year >= 1900
            if year <3000
              return true
  return false

date_to_array = (d)->
  if not d instanceof Date
    throw new Error 'date_to_list expected Date'
  year  = d.getFullYear()
  month = d.getMonth() + 1
  day   = d.getDate()
  return [year,month,day]

array_to_date = (lst)->
  expect(lst).to.be.an('array')
  year  = lst[0]
  month = lst[1] - 1
  day   = lst[2]
  if year < 1900 or year > 3000 or month == 0 or day == 0
    throw new Error "crazy Date!"
  return new Date( year,month,day )


class CouchModel extends coffee_model.Model
  #
  # a subclass of "coffee-model".Model
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
    @id  = null
    @rev = null

    for arg in args
      switch typeof arg

        when 'object'
          if is_a_database(arg)
            @set_db arg
          else
            data = arg

        when 'string'
          @id = arg
          @rev = null

        else
          throw new Error 'invalid arg to CouchModel.constructor'

    if not data
      data = {}

    if not @id
      if data._id
        @id = data._id
        data._id = undefined
        if data._rev
          @rev = data._rev
          data._rev = undefined

    super data
    @_unsaved_changes = true # until Save or Retrieve


  set:(key,val)->
    r = super key,val
    @_unsaved_changes = true
    return r

  get:(key)->
    val = super key
    return val

  get_id:->
    @id

  get_rev:->
    @rev

  has_id:->
    return (@id isnt null)

  has_rev:->
    return (@rev isnt null)

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

    # CouchDB stores "documents" in JSON
    doc = {}
    if @id
      doc._id = @id
    if @rev
      doc._rev = @rev


    # copy data into doc, one field at a time:
    for key,field of @fields
      val = @data[key]
      if field.type == 'date'
        if is_date(val)
          date_array = date_to_array(val)
          doc[key] = date_array
        else
          if val
            throw new Error "what? '#{key}' should be a date!, not a "+(typeof val)
          else
            # val is null or undefined...no problem
      else
        doc[key] = val


    # save by creating a Dominic Barnes "Document" object...
    db_doc = @db.doc(doc)
    expect(db_doc.body).to.be(doc)
    db_doc.save (err,resp)=>
      check err
      @id = resp.id
      @rev = resp.rev
      @_unsaved_changes = false
      if cb
        cb(err,resp)
      @emit 'save'


  retrieve:(cb)->
    if cb
      expect(cb).to.be.a('function')
    if not @db
      throw new Error "retrieve() called without set_db()"

    if not @id
      throw new Error "retrieve() called when id is not set"
    expect(@id).to.be.a('string')

    if @rev
      throw new Error "retrieve() called when rev is already set"

    # retrieve by creating a Dominic Barnes "Document" object....
    doc = @db.doc({_id:@id})
    doc.get (err,resp)=>
      # "get" means retrieve from the database
      if not err
        doc = resp # will have new "_rev"
                  # could anything else be changed? maybe...

        @id  = doc._id
        @rev = doc._rev

        # copy retrieved data into our data
        @data = {}
        for key,field of @fields
          val = doc[key]
          if field.type == 'date'
            if not is_date_array(val)
              throw new Error "retrieved date should be a date array"
            d = array_to_date(val)
            @data[key] = d
          else
            @data[key] = val

        @_unsaved_changes = false

        # call the user-supplied callback:
        if cb then cb(err,resp)

        @emit 'retrieve'


  reretrieve:(cb)->
    # abandon any unsaved changes, and re-retrieve from database
    if not @rev
      throw new Error "reretrieve() called when rev is not set"
    @rev = undefined
    @retrieve(cb)




  has_unsaved_changes:->
    @_unsaved_changes

exports.CouchModel = CouchModel
