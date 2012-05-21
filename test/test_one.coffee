
cmc     = require '../coffee-model-couch'
expect  = require 'expect.js'
couchdb = require 'couchdb-api' # by Dominic Barnes

server = couchdb.srv()
db     = server.db('test-coffee-model-couch')

say = console.log

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
  expect(p.data).to.have.key('_id')
  expect(p.data).not.to.have.key('_rev')
  p.save (err,ok)->
    expect(err).to.be(null)
    expect(ok).to.be.ok()
    expect(p.data).to.have.key('_id')
    expect(p.data).to.have.key('_rev')
    expect(p.get_id()).to.be('id-separate')
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
    db.drop (err,res)->
      if not err
        done()
      if err
        throw new Error 'ERROR dropping db!'

  construct_with_db:
    save:
      works:(done)->
        p = new Pet(db)
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).to.have.key('_id')
          expect(p.data).to.have.key('_rev')
          done()

  construct_with_db_and_data:
    save:
      works:(done)->
        p = new Pet(db,{name:'Snowball'})
        expect(p.get 'name').to.be('Snowball')
        expect(p.data).not.to.have.key('_id')
        expect(p.data).not.to.have.key('_rev')
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).to.have.key('_id')
          expect(p.data).to.have.key('_rev')
          done()

  construct_with_data_and_db:
    save:
      works:(done)->
        p = new Pet({name:'Snowball'},db)
        expect(p.get 'name').to.be('Snowball')
        expect(p.data).not.to.have.key('_id')
        expect(p.data).not.to.have.key('_rev')
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).to.have.key('_id')
          expect(p.data).to.have.key('_rev')
          done()

  construct_with_db_and_id:
    save:
      works:(done)->
        p = new Pet(db,'Snowball')
        expect(p.get_id()).to.be('Snowball')
        expect(p.data).to.have.key('_id')
        expect(p.data).not.to.have.key('_rev')
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).to.have.key('_id')
          expect(p.data).to.have.key('_rev')
          expect(p.get_id()).to.be('Snowball')
          expect(p.get 'name').to.be(undefined)
          done()

  construct_with_id_and_db:
    save:
      works:(done)->
        p = new Pet('Snowball',db)
        expect(p.get_id()).to.be('Snowball')
        expect(p.data).to.have.key('_id')
        expect(p.data).not.to.have.key('_rev')
        p.save (err,ok)->
          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(p.data).to.have.key('_id')
          expect(p.data).to.have.key('_rev')
          expect(p.get_id()).to.be('Snowball')
          expect(p.get 'name').to.be(undefined)
          done()

  save_with_no_id:
    and_retrieve:
      has_id_and_rev:(done)->

        pet = new Pet()
        pet.set_db(db)
        pet.set 'species','dog'
        pet.set 'name','Snowball'

        expect(pet).not.to.have.key('_id')
        expect(pet).not.to.have.key('_rev')

        pet.save (err,ok)->

          expect(err).to.be(null)
          expect(ok).to.be.ok()
          expect(pet.data).to.have.key('_id')
          expect(pet.data).to.have.key('_rev')

          pet_id = pet.get_id()

          p2 = new Pet(pet_id)
          p2.set_db(db)
          p2.retrieve (err,resp)->
            if err
              throw new Error err
            else
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
        p.on 'retrieve', ->
          done()
        p.save ->
          p.retrieve()


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


