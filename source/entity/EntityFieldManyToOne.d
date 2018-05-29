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

class EntityFieldManyToOne(T : Object) : EntityFieldObject!(T,T) {

    private ManyToOne _mode;
    private string _findSqlStr;
    private CriteriaBuilder _builder;

    this(CriteriaBuilder builder, string fileldName, string columnName, string tableName, T fieldValue, ManyToOne mode) {
        super(builder, fileldName, columnName, tableName, fieldValue, null, EntityFieldType.MANY_TO_ONE);
        _mode = mode;      
        _builder = builder; 
        _joinColumn = columnName;
        initJoinData(tableName, columnName);
    }

    private void initJoinData(string tableName, string joinColumn) {
        _joinData = new JoinSqlBuild(); 
        _joinData.tableName = _entityInfo.getTableName();
        _joinData.joinWhere = tableName ~ "." ~ joinColumn ~ " = " ~ _entityInfo.getTableName() ~ "." ~ _entityInfo.getPrimaryKeyString();
        _joinData.joinType = JoinType.LEFT;
        foreach(value; _entityInfo.getFields()) {
            _joinData.columnNames ~= value.getSelectColumn();
        }
    }

    override public JoinSqlBuild getJoinData() {
        if (_mode.fetch == FetchType.LAZY)
            return null;
        return _joinData;
    }

    public T deSerialize(Row row) {
        if (_mode.fetch == FetchType.LAZY)
            return null;
        long count = -1;
        return _entityInfo.deSerialize([row], count, 0, true);        
    }

}