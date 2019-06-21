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
import hunt.entity.EntityOption;
import hunt.entity.eql;
import hunt.logging;
import std.traits;

class EntityManager {

    public Dialect _dialect;
    public EntityOption _option;
    public Database _db;
    public string _name;
    private EntityManagerFactory _factory;
    private EntityTransaction _transaction;
    private EntitySession _EntitySession;

    this(EntityManagerFactory factory, string name, EntityOption option, Database db, Dialect dialect) {
        _factory = factory;
        _name = name;
        _option = option;
        _db = db;
        _dialect = dialect;
        _transaction = new EntityTransaction(this);
        _EntitySession = new EntitySession(this);
    }

    // ~this()
    // {
    //     if(_EntitySession)
    //         close();
    // }

    public T persist(T)(ref T entity) {
        QueryBuilder builder = _factory.createQueryBuilder();
        EntityInfo!T info = new EntityInfo!(T)(this, entity);
        builder.insert(info.getTableName()).values(info.getInsertString());
        if (info.getAutoIncrementKey().length > 0)
            builder.setAutoIncrease(info.getAutoIncrementKey());
        auto stmt = _EntitySession.prepare(builder.toString);
        int r = stmt.execute();
        info.setIncreaseKey(entity, stmt.lastInsertId);
        return entity;
    }

    public T find(T,P)(P primaryKeyOrT) {
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


    

    public int remove(T,P)(P primaryKeyOrT) {
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


    public int merge(T)(T entity) {
        CriteriaBuilder criteriaBuilder = getCriteriaBuilder();
        CriteriaUpdate!T criteriaUpdate = criteriaBuilder.createCriteriaUpdate!(T);
        Root!T r = criteriaUpdate.from(entity);
        Predicate condition = criteriaBuilder.equal(r.getPrimaryField());
        foreach(k,v; r.getEntityInfo().getFields()) {
            if (k != r.getEntityInfo().getPrimaryKeyString() && v.getColumnName() != "") {
                criteriaUpdate.set(v);    
            }
        }
        return createQuery(criteriaUpdate.where(condition)).executeUpdate();
    }

    public void flush()
    {
        //TODO 
    }

    public EqlQuery!(T) createQuery(T...)(string eql)
    {
        return new EqlQuery!(T)(eql, this);
    }

    public EqlQuery!(T) createQuery(T...)(string query_eql,Pageable page)
    {
        return new EqlQuery!(T)(query_eql,page,this);
    }

    public TypedQuery!(T,F) createQuery(T,F)(CriteriaQuery!(T,F) query) {
        return new TypedQuery!(T,F)(query, this);
    }

    public Query!(T) createQuery(T)(CriteriaDelete!T query) {
        return new Query!(T)(query, this);
    }

    public Query!(T) createQuery(T)(CriteriaUpdate!T query) {
        return new Query!(T)(query, this);
    }

    public NativeQuery createNativeQuery(string sql)
    {
        return new NativeQuery(this,sql);
    }

    public Dialect getDialect() {return _dialect;}
    public EntitySession getSession() {return _EntitySession;}
    public CriteriaBuilder getCriteriaBuilder() {return _factory.getCriteriaBuilder().setManager(this);}     
    public EntityTransaction getTransaction() {return _transaction;}
    public Database getDatabase() {return _db;}
    public string getPrefix() {return _option.database.prefix;}

    public void close() {
        if(_EntitySession)
        {
            _EntitySession.close();
            _EntitySession = null;
        }
    }
}
