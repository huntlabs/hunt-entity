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
 
module hunt.entity.EntityFieldManyToOne;

import hunt.entity;
import hunt.Nullable;
import hunt.logging.ConsoleLogger;

import std.variant;

class EntityFieldManyToOne(T : Object) : EntityFieldObject!(T,T) {

    private ManyToOne _mode;
    private string _findSqlStr;

    this(EntityManager manager, string fieldName, string columnName, string tableName, T fieldValue, ManyToOne mode) {
        super(manager, fieldName, columnName, tableName, fieldValue, null);
        _mode = mode;      
        _enableJoin = _mode.fetch == FetchType.EAGER;    
        _joinColumn = columnName;
        _columnFieldData = new ColumnFieldData();
        _columnFieldData.valueType = typeof(_entityInfo.getPrimaryValue()).stringof;

        _columnFieldData.value = new hunt.Nullable.Nullable!(typeof(_entityInfo.getPrimaryValue()))(_entityInfo.getPrimaryValue());

        initJoinData(tableName, columnName);
    }

    private void initJoinData(string tableName, string joinColumn) {
        _foreignKeyData = new ForeignKeyData();
        _foreignKeyData.columnName = joinColumn;
        _foreignKeyData.tableName = _entityInfo.getTableName();
        _foreignKeyData.primaryKey = _entityInfo.getPrimaryKeyString();
        
        _joinSqlData = new JoinSqlBuild(); 
        _joinSqlData.tableName = _entityInfo.getTableName();
        _joinSqlData.joinWhere = tableName ~ "." ~ joinColumn ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _entityInfo.getPrimaryKeyString();
        _joinSqlData.joinType = JoinType.LEFT;
        foreach(value; _entityInfo.getFields()) {
            _joinSqlData.columnNames ~= value.getSelectColumn();
        }
    }


    public T deSerialize(Row row) {
        if (_mode.fetch == FetchType.LAZY)
            return null;
        long count = -1;
        return _entityInfo.deSerialize([row], count, 0, true);        
    }

    public void setMode(ManyToOne mode) {
        _mode = mode;
        _enableJoin = _mode.fetch == FetchType.EAGER;    
    }

    public LazyData getLazyData(Row row) {
        string name = EntityExpression.getColumnAsName(_joinColumn, getTableName());
        Variant v = row.getValue(name);
        if(!v.hasValue()) {
            warningf("Can't find value for %s", name);
            return null;
        }
        
        string value = v.toString();
        version(HUNT_DEBUG) tracef("A column: %s = %s", name, value);
        LazyData ret = new LazyData(_entityInfo.getPrimaryKeyString(), value);
        return ret;        
    }

}