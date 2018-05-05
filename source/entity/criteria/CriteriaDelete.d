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
 
module entity.criteria.CriteriaDelete;

import entity;

class CriteriaDelete(T) : CriteriaBase!T
{
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!T from(T t = null) {
        super.from(t);
        _sqlBuidler.remove(_root.getTableName());
        return _root;
    }

    //P = Predicate
    public CriteriaDelete!T where(P...)(P predicates) {
        return cast(CriteriaDelete!T)super.where(predicates);
    }
}