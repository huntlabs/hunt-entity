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
 
module entity.criteria.CriteriaUpdate;

import entity;

class CriteriaUpdate(T : Object, F : Object = T) : CriteriaBase!(T,F)
{
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!(T,F) from(T t = null, F owner = null) {
        super.from(t, owner);
        _sqlBuidler.update(_root.getTableName());
        return _root;
    }
    //P = Predicate
    public CriteriaUpdate!(T,F) where(P...)(P predicates) {
        return cast(CriteriaUpdate!(T,F))super.where(predicates);
    }
    public CriteriaUpdate!(T,F) set(P)(EntityFieldInfo field, P p) {
        _criteriaBuilder.assertType!(P)(field);
        _sqlBuidler.set(field.getFullColumn(), _criteriaBuilder.getDialect().toSqlValue(p));
        return this;
    }

    public CriteriaUpdate!(T,F) set(EntityFieldInfo field) {
        _sqlBuidler.set(field.getFullColumn(), _criteriaBuilder.getDialect().toSqlValue(field.getFieldValue()));
        return this;
    }    
}
