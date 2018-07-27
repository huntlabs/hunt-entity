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
 
module entity.EntityFieldOneToOne;

import entity;

class EntityFieldOneToOne(T : Object , F : Object) : EntityFieldObject!(T,F) {
    
    private OneToOne _mode;
    private string _primaryKey;
    private bool _isMappedBy;



    this(EntityManager manager, string fileldName, string primaryKey, string columnOrjoin, string tableName, T fieldValue, OneToOne mode, F owner) {
        _mode = mode;  
        _enableJoin = _mode.fetch == FetchType.EAGER;    
        _isMappedBy = _mode.mappedBy != "";
        super(manager, fileldName, _isMappedBy ? "" : columnOrjoin, tableName, _isMappedBy ? null : fieldValue , owner);
        _primaryKey = primaryKey;
        if (_isMappedBy) {
            _joinColumn = _entityInfo.getFields[_mode.mappedBy].getJoinColumn();
        }
        else {
            _joinColumn = columnOrjoin;

            _columnFieldData = new ColumnFieldData();
            _columnFieldData.valueType = typeof(_entityInfo.getPrimaryValue()).stringof;
            if (_columnFieldData.valueType == "string" && manager !is null)
                _columnFieldData.value = manager.getDatabase().escapeLiteral(_entityInfo.getPrimaryValue().to!string);
            else
                _columnFieldData.value = _entityInfo.getPrimaryValue().to!string;

            _foreignKeyData = new ForeignKeyData();
            _foreignKeyData.columnName = columnOrjoin;
            _foreignKeyData.tableName = _entityInfo.getTableName();
            _foreignKeyData.primaryKey = _entityInfo.getPrimaryKeyString();

        }

        initJoinData(tableName);
    }

    override public string getSelectColumn() {
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
    }

    public T deSerialize(Row row) {
        if (_mode.fetch == FetchType.LAZY)
            return null;
        long count = -1;
        return _entityInfo.deSerialize([row], count);        
    }

    public LazyData getLazyData(Row row) {
        LazyData ret;
        RowData data;
        if (_isMappedBy) {
            data = row.getAllRowData(getTableName());
            if (data is null)
                return null;
            if (data.getData(_entityInfo.getPrimaryKeyString()) is null)
                return null;
            ret = new LazyData(_mode.mappedBy, data.getData(_entityInfo.getPrimaryKeyString()).value);
        }
        else {
            data = row.getAllRowData(getTableName());
            if (data is null)
                return null;
            if (data.getData(_joinColumn) is null)
                return null;
            ret = new LazyData(_entityInfo.getPrimaryKeyString(), data.getData(_joinColumn).value);
        }
        return ret;
    }

    public void setMode(OneToOne mode) {
        _mode = mode;
        _enableJoin = _mode.fetch == FetchType.EAGER;    
    }

}
