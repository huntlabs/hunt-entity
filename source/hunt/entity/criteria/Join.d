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
 
module hunt.entity.criteria.Join;

import hunt.entity;

class Join(F,T) : Root!T
{
    private JoinType _joinType;
    private EntityFieldInfo _info;
    private Root!F _from;

    this(CriteriaBuilder _builder,EntityFieldInfo info, Root!F from, JoinType joinType = JoinType.INNER) {
        _info = info;
        _joinType = joinType;
        _from = from;
        super(_builder);
    }

    public EntityInfo!T opDispatch(string name)()
    {
        return super.opDispatch!(name)();
    }

    public string getJoinOnString()
    {
        return _from.getTableName() ~ "." ~ _info.getJoinColumn() ~ " = " ~ getTableName() ~ "." ~ getEntityInfo().getPrimaryKeyString();
    }
}
