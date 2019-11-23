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
import hunt.database.base.Util;
import hunt.logging.ConsoleLogger;


class EntitySession
{

    private Database _db;
    private Transaction _trans;
    private SqlConnection _conn;

    this(Database db)
    {
        assert(db !is null);
        _db = db;
        // _conn = _db.getConnection();
    }

    ~this()
    {
        Util.info("TODO: Closing EntitySession in ~this()");
        // version(HUNT_ENTITY_DEBUG) infof("Closing EntitySession in ~this()"); // bug
        // close();
    }

    public void beginTransaction()
    {
        checkConnection();
        if(_trans is null)
            _trans = _db.getTransaction(getConnection());
    }

    public void commit()
    {
        assert(_trans !is null, "Execute beginTransaction first");
        checkConnection();
        _trans.commit();
    }

    public void rollback()
    {
        assert(_trans !is null, "Execute beginTransaction first");
        checkConnection();
        _trans.rollback();
    }

    public Statement prepare(string sql)
    {
        return _db.prepare(getConnection(), sql);
    }

	int execute(string sql)
	{
        version(HUNT_DEBUG) trace(sql);
		RowSet rs = getConnection().query(sql);
		return rs.rowCount();
	}

	RowSet query(string sql)
	{
		version (HUNT_SQL_DEBUG) info(sql);
		RowSet rs = getConnection().query(sql);
		return rs;
	}

    public SqlConnection getConnection() 
    {
        if(_conn is null)
           _conn = _db.getConnection(); 
        return _conn;
    }

    public Transaction getTransaction() {return _trans;}

    public void close() 
    {
        Util.info("closing");
        if (_conn !is null && _db !is null)
        {
            Util.info("closing connection");
            _db.relaseConnection(_conn);
        }
        _conn = null;
    }

    private void checkConnection()
    {
        if (_conn is null)
            throw new EntityException("the entity connection haved release");
    }


}



