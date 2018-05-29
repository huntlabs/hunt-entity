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



    this(CriteriaBuilder builder, string fileldName, string primaryKey, string columnOrjoin, string tableName, OneToOne mode, F owner) {
        _mode = mode;      
        _isMappedBy = _mode.mappedBy != "";
        super(builder, fileldName, _isMappedBy ? "" : columnOrjoin, tableName, null, owner, EntityFieldType.ONE_TO_ONE);
        _primaryKey = primaryKey;
        if (_isMappedBy) {
            _joinColumn = _entityInfo.getFields[_mode.mappedBy].getJoinColumn();
        }
        else {
            _joinColumn = columnOrjoin;
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
        _joinData = new JoinSqlBuild(); 
        _joinData.tableName = _entityInfo.getTableName();
        if (_isMappedBy) {
            _joinData.joinWhere = tableName ~ "." ~ _primaryKey ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _joinColumn;
        }
        else {
            _joinData.joinWhere = tableName ~ "." ~ _joinColumn ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _entityInfo.getPrimaryKeyString();
        }
        _joinData.joinType = JoinType.LEFT;
        foreach(value; _entityInfo.getFields()) {
            _joinData.columnNames ~= value.getSelectColumn();
        }
    }

    public T deSerialize(Row row) {
        log(_mode.fetch == FetchType.LAZY);
        if (_mode.fetch == FetchType.LAZY)
            return null;
        long count = -1;
        return _entityInfo.deSerialize([row], count, 0);        
    }

}
