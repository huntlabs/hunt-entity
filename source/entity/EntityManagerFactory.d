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
 
module entity.EntityManagerFactory;

import entity;

class EntityManagerFactory
{

    public Dialect _dialect;
    public DatabaseConfig _config;
    public Database _db;
    public string _name;
    private CriteriaBuilder _criteriaBuilder;

    public this(string name, DatabaseConfig config)
    {
        _name = name;
        _config = config;
        _db = new Database(config);
        _dialect = _db.createDialect();
        _criteriaBuilder = new CriteriaBuilder(this);
    }

    public EntityManager createEntityManager()
    {
        return new EntityManager(this, _name, _config, _db, _dialect);
    }

    public SqlBuilder createSqlBuilder() {
        return _db.createSqlBuilder();
    }
    
    public Dialect getDialect() {return _dialect;}
    public Database getDatabase() {return _db;}
    public CriteriaBuilder getCriteriaBuilder() {return _criteriaBuilder;}

    public void close()
    {
        if (_db)
            _db.close();

        _db = null;
    }
}
