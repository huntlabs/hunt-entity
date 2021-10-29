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
 
module hunt.entity.criteria.CriteriaBase;

import hunt.entity;
import hunt.logging;

class CriteriaBase(T : Object, F : Object = T)
{

    protected Root!(T,F) _root;
    protected CriteriaBuilder _criteriaBuilder;
    protected QueryBuilder _sqlBuidler;


    this(CriteriaBuilder criteriaBuilder) {
        _criteriaBuilder = criteriaBuilder;
        _sqlBuidler = criteriaBuilder.createQueryBuilder();
    }

    Root!(T,F) from(T t = null, F owner = null) {
        _root = new Root!(T,F)(_criteriaBuilder, t is null ? null : Common.sampleCopy(t), owner);
        // logDebug("Form table : ",_root.getTableName());
        _sqlBuidler.from(_root.getTableName());
        _root.autoJoin();
        return _root;
    }

    Root!(T,F) manyToManyFrom(T t = null, F owner = null ,string mapped = string.init) {
        _root = new Root!(T,F)(_criteriaBuilder, t is null ? null : Common.sampleCopy(t), owner);
        auto entityInfo = _root.getEntityInfo();
         auto filedInfo = entityInfo.getSingleField(mapped);
         if(filedInfo !is null)
            filedInfo.setEnableJoin(true);
        _sqlBuidler.from(_root.getTableName());
        _root.autoJoin();
        return _root;
    }

    Root!(T,F) getRoot() {return _root;}

    CriteriaBase!(T,F) where(P...)(P predicates) {
        string s = " ";
        foreach(k, v; predicates) {
            s ~= v.toString();
            if (k != predicates.length-1) 
                s ~= " AND ";
        }
        _sqlBuidler.where(s);
        return this;
    }

    CriteriaBase!(T,F) where(R)(Comparison!R cond) {
        _sqlBuidler.where(cond);
        return this;
    }

    override string toString() {
        return _sqlBuidler.toString();
    }

    void setEnableJoin(bool flg)
    {
        _root.setEnableJoin(flg);
    }
}