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
 
module hunt.entity.TypedQuery;

import hunt.entity;

class TypedQuery(T : Object, F : Object = T) {


    private string _sqlSting;
    private CriteriaQuery!(T,F) _query;
    private EntityManager _manager;

    this(CriteriaQuery!(T,F) query, EntityManager manager) {
        _query = query;
        _manager = manager;
    }

    public Object getSingleResult() {
        Object[] ret = _getResultList();
        if (ret.length == 0)
            return null;
        return ret[0];
    }

    public T[] getResultList() {
        Object[] ret = _getResultList();
        if (ret.length == 0) {
            return null;
        }
        return cast(T[])ret;
    }

    public TypedQuery!(T,F) setMaxResults(int maxResult) {
        _query.getQueryBuilder().limit(maxResult);
        return this;
    }

    public TypedQuery!(T,F) setFirstResult(int startPosition) {
        _query.getQueryBuilder().offset(startPosition);
        return this;
    }

    private Object[] _getResultList() {
        Object[] ret;
        long count = -1;
        auto stmt = _manager.getSession().prepare(_query.toString());
		auto res = stmt.query();
        Row[] rows;
        foreach(value; res) {
            rows ~= value;
        }
        foreach(k,v; rows) {
            Object t = _query.getRoot().deSerialize(rows, count, cast(int)k);
            if (t is null) {
                if (count != -1) {
                    ret ~= new Long(count);
                }
                else {
                    throw new EntityException("getResultList has an null data");
                }
            }
            ret ~= t;
        }
		return ret;
    }




}