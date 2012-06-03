
# test coffee-model-couch

cmc     = require '../coffee-model-couch'
expect  = require 'expect.js'
couchdb = require 'couchdb-api' # by Dominic Barnes

server = couchdb.srv()
db     = server.db('test-coffee-model-couch')

say = console.log

check = (err,desc='')->
  if err
    s = desc + ' : ' + err
    throw new Error s

class Pet extends cmc.CouchModel
  fields:
    species:
      type:'string'
    name:
      type:'string'


test_id = null
test_data = null # set in "beforeEach"


test_3_arg_constructor = (p,done)->
  expect(p.get_id()).to.be('id-separate')
  expect(p.has_id()).to.be(true)
  expect(p.has_rev()).to.be(false)
  p.save (err,ok)->
    expect(err).to.be(null)
    expect(ok).to.be.ok()
    #expect(p.data).to.have.key('_id')
    #expect(p.data).to.have.key('_rev')
    expect(p.get_id()).to.be('id-separate')
    expect(p.has_rev()).to.be(true)
    expect(p.get 'name').to.be('Snowball')
    done()

# Mocha tests ( mocha -u exports )
module.exports =

  beforeEach:(done)->

    test_data =
      _id : "id-in-data"
      name:'Snowball'
      species: 'dog'

    test_id = 'id-separate'

    db = server.db('test-coffee-model-couch')

    db.drop ->
      # ok if err
      db.create (err,res)->
        if not err
          done()

  afterEach:(done)->
    if false # drop db immediately?
      db.drop (err,res)->
        if not err
          done()
        if err
          throw new Error 'ERROR dropping db!'
    else
      done()

  construct_with_db:
    save:
      works:(done)->
        p = new Pet(db)
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()

          id = p.get_id()
          rev = p.get_rev()

          #say 'after save doc:'
          #say 'id='+id
          #say 'rev='+rev

          expect(p.get_id()).to.be.ok()
          expect(p.get_rev()).to.be.ok()
          done()

  construct_with_db_and_data:
    save:
      works:(done)->
        p = new Pet(db,{name:'Snowball'})
        expect(p.get 'name').to.be('Snowball')
        expect(p.has_id()).to.be(false)
        expect(p.has_rev()).to.be(false)
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.has_id()).to.be(true)
          expect(p.has_rev()).to.be(true)
          done()

  construct_with_data_and_db:
    save:
      works:(done)->
        p = new Pet({name:'Snowball'},db)
        expect(p.get 'name').to.be('Snowball')
        expect(p.has_id()).to.be(false)
        expect(p.has_rev()).to.be(false)
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).not.to.have.key('_id')
          expect(p.data).not.to.have.key('_rev')
          expect(p.has_id()).to.be(true)
          expect(p.has_rev()).to.be(true)
          done()

  construct_with_db_and_id:
    save:
      works:(done)->
        p = new Pet(db,'Snowball')
        expect(p.get_id()).to.be('Snowball')
        expect(p.data).not.to.have.key('_id')
        expect(p.data).not.to.have.key('_rev')
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).not.to.have.key('_id')
          expect(p.data).not.to.have.key('_rev')
          expect(p.has_id()).to.be(true)
          expect(p.has_rev()).to.be(true)
          expect(p.get_id()).to.be('Snowball')
          expect(p.get 'name').to.be(undefined)
          done()

  construct_with_id_and_db:
    save:
      works:(done)->
        p = new Pet('Snowball',db)
        expect(p.get_id()).to.be('Snowball')
        expect(p.data).not.to.have.key('_id')
        expect(p.data).not.to.have.key('_rev')
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).not.to.have.key('_id')
          expect(p.data).not.to.have.key('_rev')
          expect(p.has_id()).to.be(true)
          expect(p.has_rev()).to.be(true)
          expect(p.get_id()).to.be('Snowball')
          expect(p.get 'name').to.be(undefined)
          done()


  save_with_no_id:
    and_retrieve:
      has_id_and_rev:(done)->

        p = new Pet()
        p.set_db(db)
        p.set 'species','dog'
        p.set 'name','Snowball'
        p.save (err,ok)->

          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).not.to.have.key('_id')
          expect(p.data).not.to.have.key('_rev')
          expect(p.data).not.to.have.key('id')
          expect(p.data).not.to.have.key('rev')
          expect(p.has_id()).to.be(true)
          expect(p.has_rev()).to.be(true)

          pet_id = p.get_id()

          p2 = new Pet(pet_id)
          p2.set_db(db)
          p2.retrieve (err,resp)->
            check err
            name = p2.get 'name'
            expect(name).to.be('Snowball')
            done()


  construct_with_args_in_any_order:
    works_for:
      db_id_data:(done)->
        test_3_arg_constructor( new Pet( db, test_id, test_data ),done)
      db_data_id:(done)->
        test_3_arg_constructor( new Pet( db, test_data, test_id ),done)
      id_data_db:(done)->
        test_3_arg_constructor( new Pet( test_id, test_data, db ),done)
      id_db_data:(done)->
        test_3_arg_constructor( new Pet( test_id, db, test_data ),done)
      data_db_id:(done)->
        test_3_arg_constructor( new Pet( test_data, db, test_id ),done)
      data_id_db:(done)->
        test_3_arg_constructor( new Pet( test_data, test_id, db ),done)


  has_unsaved_changes:

    on_retrieved_object:
      is_false:(done)->
        p = new Pet(db,test_id,test_data)
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          id = p.get_id()
          p2 = new Pet(db,id)
          p2.retrieve (err,ok)->
            expect(err).to.be(null)
            expect(p2.has_unsaved_changes()).to.be(false)
            done()


    on_new_object:
      is_true:(done)->
        p = new Pet(test_data)
        expect(p.has_unsaved_changes()).to.be(true)
        done()


    on_save:
      is_cleared:(done)->

        p = new Pet(db,test_data)
        expect(p.get_id()).to.be('id-in-data')

        p.set 'name', 'Snowball_2'
        expect(p.has_unsaved_changes()).to.be(true)

        p.save (err,ok)->
          expect(err).to.be(null)
          expect(p.get 'name').to.be('Snowball_2')
          expect(p.has_unsaved_changes()).to.be(false)
          done()


  event:

    on_save:
      works:(done)->
        p = new Pet(test_data,db)
        p.on 'save',->
          done()
        p.save()

    on_retrieve:
      works:(done)->
        p = new Pet(db,test_data)
        p.save ->
          p2 = new Pet db,p.id
          p2.on 'retrieve', ->
            done()
          p2.retrieve()


  boolean_field:
    save:
      works:(done)->

        class Pet extends cmc.CouchModel
          fields:
            name:
              type:'string'
            is_white:
              type:'boolean'

        snowball = new Pet
          name:'Snowball'
          is_white:true

        snowball.set_db(db)

        snowball.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          done()


      and_retrieve:(done)->

        class Pet extends cmc.CouchModel
          fields:
            name:
              type:'string'
            is_white:
              type:'boolean'

        snowball = new Pet
          name:'Snowball'
          is_white:true

        snowball.set_db db

        snowball.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()

          id = snowball.get_id()
          p = new Pet(id,db)
          p.retrieve (err,ok)->
            expect(err).to.be(null)
            expect(p.get 'is_white').to.be(true)
            done()

  validation:
    errors:
      prevent_save:(done)->

        class Pet extends cmc.CouchModel
          fields:
            species:
              type:'string'
            name:
              type:'string'
          validations:
            check_sillyness:(err)->
              if @data.name == 'Snowball'
                err "name is silly"

        p = new Pet db,
          name:'Snowball'
        r = p.validate()
        expect(r.PASS).to.be(false)
        expect(r.errors).to.have.length(1)

        p.save (err,ok)->
          expect(err).not.to.be(null)
          expect(p.has_unsaved_changes()).to.be(true)
          done()


  dates:
    save:
      and_retrieve:(done)->

        class Pet extends cmc.CouchModel
          fields:
            date_of_birth:
              type:'date'

        p = new Pet db
        dt = new Date(2012,05,02) # june 2,2012
        p.set 'date_of_birth', dt
        p.save (err,ok)->
          check err
          id = p.get_id()
          p2 = new Pet id,db
          p2.retrieve (err,ok)->
            check err,'retrieve'
            new_dt = p2.get 'date_of_birth'
            expect( new_dt instanceof Date ).to.be(true)
            expect(new_dt.getFullYear()).to.be(2012)
            expect(new_dt.getMonth()).to.be(5)
            expect(new_dt.getDate()).to.be(2)
            # you cant' just use == on two dates!
            if new_dt.getTime() != dt.getTime()
              e = new Error "Date Failure"
              say 'DATE FAIL'
              say 'expected date : ' + String(dt)
              say 'actual   date : ' + String(new_dt)
              e.expected = String(dt)
              e.actual = String(new_dt)
              throw e
            else
              done()

  saving_repeatedly:
    is_ok:
      it_works:(done)->

        class Pet extends cmc.CouchModel
          fields:
            name:
              type:'string'

        p = new Pet
        p.set_db db
        p.save (err,ok)->
          p.set 'name','Snowball'
          p.save (err,ok)->
            expect(p.get 'name').to.be('Snowball')
            p.set 'name','Snowball2'
            p.save (err,ok)->
              expect(p.get 'name').to.be('Snowball2')
              done()



  retrieving_twice:
    would_lose_data:
      so_its_not_allowed:(done)->

        class Pet extends cmc.CouchModel
          fields:
            name:
              type:'string'

        p = new Pet
        p.set_db db
        p.set 'name','Snowball'
        p.save (err,ok)->
          expect()
          p.set 'name', 'Beelzebub'
          try
            p.retrieve()
          catch e
            expect(e.toString()).to.be('Error: retrieve() called when rev is already set')
            done()
            return

          throw new Exception "allowed retrieve twice!"

  reretrieve:
    abandons_unsaved_changes:
      allowed_after_save:(done)->
        p = new Pet db
        p.save ->
          p.reretrieve (err,ok)->
            if ok then done()

      allowed_after_retrieve:(done)->
        p = new Pet db
        p.save ->
          p2 = new Pet db, p.id
          p2.retrieve ->
            p2.reretrieve ->
              done()

      not_allowed_if_not_saved:(done)->
        p = new Pet db
        try
          p.reretrieve()
        catch e
          done()
          return
        throw new Error 'reretrieve allowed when not saved'



















