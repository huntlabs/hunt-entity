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
 
module hunt.entity.NativeQuery;

import hunt.entity;


class NativeQuery {

    private string _nativeSql;
    private EntityManager _manager;

    this(EntityManager manager,string sql) {
        _manager = manager;
        _nativeSql = sql;
    }

    public ResultSet getResultList() {
       
        auto stmt = _manager.getSession().prepare(_nativeSql);
		return stmt.query();
    }

    public int executeUpdate() {
        auto stmt = _manager.getSession().prepare(_nativeSql); 
        //TODO update 时 返回的row line count 为 0
        return stmt.execute();
    }

}
