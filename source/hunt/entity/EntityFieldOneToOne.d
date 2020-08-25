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
 
module hunt.entity.EntityFieldOneToOne;

import hunt.entity;
import hunt.Exceptions;
import hunt.logging.ConsoleLogger;

import std.range;
import std.string;
import std.variant;

class EntityFieldOneToOne(T : Object , F : Object) : EntityFieldObject!(T,F) {
    
    private OneToOne _mode;
    private string _primaryKey;
    private bool _isMappedBy;

    this(EntityManager manager, string fieldName, string primaryKey, string columnOrjoin, 
            string tableName, T fieldValue, OneToOne mode, F owner) {
        string mappedBy = mode.mappedBy;

        _mode = mode;  
        _enableJoin = _mode.fetch == FetchType.EAGER;    
        _isMappedBy = !mappedBy.empty();

        super(manager, fieldName, 
            _isMappedBy ? "" : columnOrjoin, 
            tableName, 
            _isMappedBy ? null : fieldValue , 
            owner);

        _primaryKey = primaryKey;
        if (_isMappedBy) {
            EntityFieldInfo fieldInfo = _entityInfo.getSingleField(mappedBy);
            if(fieldInfo is null) {
                string msg = format("Can't get the field info for [%s] in %s", mappedBy, T.stringof);
                warningf(msg);
                throw new EntityException(msg);
                // _joinColumn = columnOrjoin;
            } else {
                _joinColumn = fieldInfo.getJoinColumn();
            }
        }
        else 
        {
            _joinColumn = columnOrjoin;
            _columnFieldData = Variant(_entityInfo.getPrimaryValue());

            // _columnFieldData = new ColumnFieldData();
            // _columnFieldData.valueType = typeof(_entityInfo.getPrimaryValue()).stringof;
            // // if (_columnFieldData.valueType == "string" && manager !is null)
            // //     _columnFieldData.value = /*manager.getDatabase().escapeLiteral*/(_entityInfo.getPrimaryValue().to!string);
            // // else
            // //     _columnFieldData.value = _entityInfo.getPrimaryValue().to!string;
            //  _columnFieldData.value = new hunt.Nullable.Nullable!(typeof(_entityInfo.getPrimaryValue()))(_entityInfo.getPrimaryValue());

            _foreignKeyData = new ForeignKeyData();
            _foreignKeyData.columnName = columnOrjoin;
            _foreignKeyData.tableName = _entityInfo.getTableName();
            _foreignKeyData.primaryKey = _entityInfo.getPrimaryKeyString();

        }

        initJoinData(tableName);
    }

    override string getSelectColumn() {
        if (_isMappedBy)
            return "";
        else 
            return super.getSelectColumn();
    }

    private void initJoinData(string tableName) {
        _joinSqlData = new JoinSqlBuild(); 
        _joinSqlData.tableName = _entityInfo.getTableName();
        if (_isMappedBy) {
            _joinSqlData.joinWhere = tableName ~ "." ~ _primaryKey ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _joinColumn;
        }
        else {
            _joinSqlData.joinWhere = tableName ~ "." ~ _joinColumn ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _entityInfo.getPrimaryKeyString();
        }
        _joinSqlData.joinType = JoinType.LEFT;
        foreach(value; _entityInfo.getFields()) {
            _joinSqlData.columnNames ~= value.getSelectColumn();
        }
        // logDebug("one to one join sql : %s ".format(_joinSqlData));

    }

    T deSerialize(Row row) {
        tracef("For %s from a row, id: %d", T.stringof, _owner.id);
        if (_mode.fetch == FetchType.LAZY)
            return null;
        long count = -1;
        return _entityInfo.deSerialize([row], count);        
    }

    LazyData getLazyData(Row row) {
        LazyData ret;

        string primaryKeyName = _entityInfo.getPrimaryKeyString();
        if (_isMappedBy) {
            
            string name = EntityExpression.getColumnAsName(primaryKeyName, getTableName());
            Variant v = row.getValue(name);
            if(!v.hasValue()) {
                version(HUNT_DEBUG) warningf("Can't find value for %s", name);
                return null;
            }
            
            string value = v.toString();
            version(HUNT_ENTITY_DEBUG) tracef("A column: %s = %s", name, value);
            ret = new LazyData(_mode.mappedBy, value);
        } else {
            string name = EntityExpression.getColumnAsName(_joinColumn, getTableName());
            Variant v = row.getValue(name);
            if(!v.hasValue()) {
                version(HUNT_DEBUG) warningf("Can't find value for %s", name);
                return null;
            }
            
            string value = v.toString();
            version(HUNT_ENTITY_DEBUG) tracef("A column: %s = %s", name, value);                
            ret = new LazyData(primaryKeyName, value);
        }        
        return ret;
    }

    void setMode(OneToOne mode) {
        _mode = mode;
        _enableJoin = _mode.fetch == FetchType.EAGER;    
    }

}
