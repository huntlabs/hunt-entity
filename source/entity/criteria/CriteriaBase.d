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
 
module entity.criteria.CriteriaBase;

import entity;

class CriteriaBase(T)
{

    protected Root!T _root;
    protected CriteriaBuilder _criteriaBuilder;
    protected SqlBuilder _sqlBuidler;


    this(CriteriaBuilder criteriaBuilder) {
        _criteriaBuilder = criteriaBuilder;
        _sqlBuidler = criteriaBuilder.createSqlBuilder();
    }

    public Root!T from(T t = null) {
        _root = new Root!(T)(_criteriaBuilder, t); 
        _sqlBuidler.from(_root.getTableName());
        return _root;
    }

    public Root!T getRoot() {return _root;}

    public CriteriaBase!T where(P...)(P predicates) {
        string s = " ";
        foreach(k, v; predicates) {
            s ~= v.toString();
            if (k != predicates.length-1) 
                s ~= " AND ";
        }
        _sqlBuidler.where(s);
        return this;
    }

    override public string toString() {
        return _sqlBuidler.build().toString();
    }
}