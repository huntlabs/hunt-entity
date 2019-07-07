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
 
module hunt.entity.EntitySession;

import hunt.entity;

class EntitySession
{

    // private EntityManager _manager;
    private Database _db;
    private Transaction _trans;

    private Connection _conn;

    this(Database db)
    {
        // _manager = manager;
        assert(db !is null);
        _db = db;
        _conn = _db.getConnection();
        _trans = _db.getTransaction(_conn);
    }

    // ~this()
    // {
    //     if(_conn)
    //         close();
    // }

    public void beginTransaction()
    {
        checkConnection();
        _trans.begin();
    }
    public void commit()
    {
        checkConnection();
        _trans.commit();
    }
    public void rollback()
    {
        checkConnection();
        _trans.rollback();
    }

    public TransStatement prepare(string sql)
    {
        if(_conn is null)
           _conn = _db.getConnection();  
        return new TransStatement(_conn, sql);
    }

    public Connection getConnection() 
    {
        if(_conn is null)
           _conn = _db.getConnection(); 
        return _conn;
    }

    public Transaction getTransaction() {return _trans;}

    public void close()
    {
        if (_conn !is null && _db !is null)
        {
            _db.relaseConnection(_conn);
        }
        _conn = null;
    }

    private void checkConnection()
    {
        if (_conn is null)
            throw new EntityException("the entity connection haved release");
        // _conn.ping();
    }


}



