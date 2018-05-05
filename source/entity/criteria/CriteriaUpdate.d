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

class CriteriaUpdate(T) : CriteriaBase!T
{
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!T from(T t = null) {
        super.from(t);
        _sqlBuidler.update(_root.getTableName());
        return _root;
    }
    //P = Predicate
    public CriteriaUpdate!T where(P...)(P predicates) {
        return cast(CriteriaUpdate!T)super.where(predicates);
    }
    public CriteriaUpdate!T set(P)(EntityFieldInfo field, P p) {
        _criteriaBuilder.assertType!(P)(field);
        _sqlBuidler.set(field.getFullColumn(), _criteriaBuilder.getDialect().toSqlValue(p));
        return this;
    }

    public CriteriaUpdate!T set(EntityFieldInfo field) {
        _sqlBuidler.set(field.getFullColumn(), _criteriaBuilder.getDialect().toSqlValue(field.getFieldValue()));
        return this;
    }    
}
