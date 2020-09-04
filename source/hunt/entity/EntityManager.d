/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.entity.EntityManager;

import hunt.entity;
import hunt.entity.dialect;
import hunt.entity.EntityOption;
import hunt.entity.eql;
import hunt.logging;
import hunt.util.Common;

import std.array;
import std.traits;

class EntityManager : Closeable {

    Dialect _dialect;
    EntityOption _option;
    Database _db;
    string _name;
    // private EntityManagerFactory _factory;
    private CriteriaBuilder _criteriaBuilder;
    private EntityTransaction _transaction;
    private EntitySession _entitySession;

    this(CriteriaBuilder criteriaBuilder, string name, EntityOption option, Database db, Dialect dialect) {
        // _factory = factory;
        _criteriaBuilder = criteriaBuilder;
        _name = name;
        _option = option;
        _db = db;
        _dialect = dialect;
        _transaction = new EntityTransaction(this);
        // _entitySession = new EntitySession(db);
    }

    ~this()
    {
        // version(HUNT_ENTITY_DEBUG) infof("Closing EntityManager in ~this()"); // bug
        // close();
    }

    T persist(T)(ref T entity) {
        QueryBuilder builder = _db.createQueryBuilder(); // _factory.createQueryBuilder();
        EntityInfo!T info = new EntityInfo!(T)(this, entity);
        builder.insert(info.getTableName()).values(info.getInsertString());

        string autoIncrementKey = info.getAutoIncrementKey();
        if (!autoIncrementKey.empty())
            builder.setAutoIncrease(autoIncrementKey);
        Statement stmt = getSession().prepare(builder.toString);
        int r = stmt.execute(autoIncrementKey);

        version(HUNT_ENTITY_DEBUG) {
            infof("affected: %d, autoIncrementKey: %s, lastInsertId: %d", r, autoIncrementKey, stmt.lastInsertId());
        }

        info.setIncreaseKey(entity, stmt.lastInsertId);
        return entity;
    }

    T find(T,P)(P primaryKeyOrT) {
        CriteriaBuilder criteriaBuilder = getCriteriaBuilder();
        CriteriaQuery!T criteriaQuery = criteriaBuilder.createQuery!(T);
        Root!T r;
        Predicate condition;
        static if (is(P == T)) {
            r = criteriaQuery.from(primaryKeyOrT);
            condition = criteriaBuilder.equal(r.getPrimaryField());
        }
        else {
            r = criteriaQuery.from();
            condition = criteriaBuilder.equal(r.getPrimaryField(), primaryKeyOrT);
        }
        TypedQuery!T query = createQuery(criteriaQuery.select(r).where(condition));
        return cast(T)(query.getSingleResult());
    }


    int remove(T,P)(P primaryKeyOrT) {
        CriteriaBuilder criteriaBuilder = getCriteriaBuilder();
        CriteriaDelete!T criteriaDelete = criteriaBuilder.createCriteriaDelete!(T);
        Root!T r;
        Predicate condition;
        static if (is(P == T)) {
            r = criteriaDelete.from(primaryKeyOrT);
            condition = criteriaBuilder.equal(r.getPrimaryField());
        }
        else {
            r = criteriaDelete.from();
            condition = criteriaBuilder.equal(r.getPrimaryField(), primaryKeyOrT);
        }
        return createQuery(criteriaDelete.where(condition)).executeUpdate();
    }

    int merge(T)(T entity) {
        CriteriaBuilder criteriaBuilder = getCriteriaBuilder();
        CriteriaUpdate!T criteriaUpdate = criteriaBuilder.createCriteriaUpdate!(T);
        Root!T r = criteriaUpdate.from(entity);
        Predicate condition = criteriaBuilder.equal(r.getPrimaryField());

        string primaryKey = r.getEntityInfo().getPrimaryKeyString();

        EntityFieldInfo[string] fields = r.getEntityInfo().getFields();

        foreach(string k, EntityFieldInfo v; fields) {
            string columnName = v.getColumnName();

            version(HUNT_ENTITY_DEBUG) tracef("Field: %s, Column: %s", k, columnName);
            if(columnName == primaryKey || columnName.empty()) {
                version(HUNT_ENTITY_DEBUG) warningf("primaryKey skipped, Field: %s, Column: %s", k, columnName);
                continue;
            }

            criteriaUpdate.set(v);
        }
        return createQuery(criteriaUpdate.where(condition)).executeUpdate();
    }

    void flush()
    {
        //TODO 
    }

    EqlQuery!(T) createQuery(T...)(string eql)
    {
        return new EqlQuery!(T)(eql, this);
    }

    EqlQuery!(T) createQuery(T...)(string query_eql,Pageable page)
    {
        return new EqlQuery!(T)(query_eql,page,this);
    }

    TypedQuery!(T,F) createQuery(T,F)(CriteriaQuery!(T,F) query) {
        return new TypedQuery!(T,F)(query, this);
    }

    Query!(T) createQuery(T)(CriteriaDelete!T query) {
        return new Query!(T)(query, this);
    }

    Query!(T) createQuery(T)(CriteriaUpdate!T query) {
        return new Query!(T)(query, this);
    }

    NativeQuery createNativeQuery(string sql)
    {
        return new NativeQuery(this,sql);
    }

    Dialect getDialect() {return _dialect;}

    EntitySession getSession() {
        if(_entitySession is null) {
            version(HUNT_DEBUG) info("Creating a new session");
            _entitySession = new EntitySession(_db);
        }
        return _entitySession;
    }

    CriteriaBuilder getCriteriaBuilder() {return _criteriaBuilder.setManager(this);}     
    EntityTransaction getTransaction() {return _transaction;}

    deprecated("Using getSession instead.")
    Database getDatabase() {return _db;}


    DatabaseOption getDbOption() {
        return _db.getOption();
    }
    
    string getPrefix() {return _option.database.prefix;}

    void close() {
        if(_entitySession)
        {
            _entitySession.close();
        }
    }
}
