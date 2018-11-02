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
 
module hunt.entity.criteria.CriteriaDelete;

import hunt.entity;

class CriteriaDelete(T : Object, F : Object = T) : CriteriaBase!(T,F)
{
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!(T,F) from(T t = null, F owner = null) {
        super.from(t, owner);
        _sqlBuidler.del(_root.getTableName());
        return _root;
    }
    //string
    public CriteriaDelete!(T,F) where(R)(Comparison!R cond) {
        return cast(CriteriaDelete!(T,F))super.where(cond);
    }
    //P = Predicate
    public CriteriaDelete!(T,F) where(P...)(P predicates) {
        return cast(CriteriaDelete!(T,F))super.where(predicates);
    }
}