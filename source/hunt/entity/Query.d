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
 
module hunt.entity.Query;

import hunt.entity;


class Query(T) {

    private string _sqlSting;
    private CriteriaBase!T _criteria;
    private EntityManager _manager;
    private int _lastInsertId = -1;
    private int _affectRows = 0;
    
    this(CriteriaBase!T criteria, EntityManager manager) {
        _criteria = criteria;
        _manager = manager;
        _sqlSting = criteria.toString();
    }
 
    public int executeUpdate() {
        auto stmt = _manager.getSession().prepare(_sqlSting); 
        _lastInsertId = stmt.lastInsertId();
        _affectRows = stmt.affectedRows();
        return stmt.execute();
    }

    public int lastInsertId()
    {
        return _lastInsertId;    
    }
    
	public int affectedRows()
    {
        return _affectRows;    
    }
}
