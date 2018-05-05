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
 
module entity.EntityFieldManyToOne;

import entity;

class EntityFieldManyToOne(T) : EntityFieldInfo
{
    private ManyToOne _mode;
    private T _value;
    private EntityInfo!T _entityInfo;

    // private Root!T _root;
    this( string fileldName, string columnName, string tableName, T fieldValue, ManyToOne mode)
    {
        super(fileldName, columnName, Variant(fieldValue), tableName);
        _mode = mode;
        _joinColumn = columnName;
        _value = fieldValue;
        // _root = new 
    }

    public void deSerialize(Dialect dialect, Row row, ref T ret)
    {
        if (_entityInfo is null)
            _entityInfo = new EntityInfo!T(dialect);

        long count;
        ret = _entityInfo.deSerialize(row, count);
    }
}
