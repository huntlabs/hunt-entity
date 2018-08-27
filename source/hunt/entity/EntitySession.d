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

    private EntityManager _manager;

    private Transaction _trans;

    private Connection _conn;

    this(EntityManager manager)
    {
        _manager = manager;
        _conn = manager.getDatabase().getConnection();
        _trans = manager.getDatabase().getTransaction(_conn);
    }

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

    public Statement prepare(string sql)
    {
        checkConnection();
        return _trans.prepare(sql);
    }

    public Connection getConnection() {return _conn;}

    public Transaction getTransaction() {return _trans;}

    public void close()
    {
        if (_conn)
            _manager.getDatabase().closeConnection(_conn);
        _conn = null;
    }

    private void checkConnection()
    {
        if (_conn is null)
            throw new EntityException("the entity connection is poor");
    }


}



