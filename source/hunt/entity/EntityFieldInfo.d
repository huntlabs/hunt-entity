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
 
module hunt.entity.EntityFieldInfo;

import hunt.entity;
import std.format;
import std.variant;

class EntityFieldInfo : EntityExpression
{
    protected string _joinColumn;
    protected string _inverseJoinColumn;
    protected string _joinTable;
    protected string _joinPrimaryKey;
    protected ForeignKeyData _foreignKeyData;
    protected JoinSqlBuild _joinSqlData;
    // protected ColumnFieldData _columnFieldData;
    protected Variant _columnFieldData;
    protected bool _isMainMapped;
    protected bool _enableJoin = true;

    private string _fieldName;
    private bool _nullable = true;
    private bool _primary;
    private bool _auto;

    public this(string fieldName, string columnName, string tableName) {
        super(columnName, tableName);
        _fieldName = fieldName;
    }

    public void setNullable(bool b) {_nullable = b;}
    public bool getNullable() {return _nullable;}

    public void setPrimary(bool b) {_primary = b;}
    public bool getPrimary() {return _primary;}

    public void setAuto(bool b) {_auto = b;}
    public bool getAuto() {return _auto;}

    public bool isMainMapped() {return _isMainMapped;}

    deprecated("Using getFieldName instead.")
    public string getFileldName() {return _fieldName;}
    public string getFieldName() {return _fieldName;}
    public string getJoinColumn() {return _joinColumn;}
    public string getInverseJoinColumn() {return _inverseJoinColumn;}
    public string getJoinTable() {return _joinTable;}
    public string getJoinPrimaryKey() {return _joinPrimaryKey;}
    public ForeignKeyData getForeignKeyData() {return _foreignKeyData;}

    public JoinSqlBuild getJoinSqlData() {return _joinSqlData;}

    public bool isEnableJoin() {return _enableJoin;}
    public void setEnableJoin(bool en) { _enableJoin = en;}

    public Variant getColumnFieldData() {return _columnFieldData;}

    override string toString() {
        return format("isPrimary: %s, TableName:%s, FileldName: %s, ColumnName: %s, JoinTable: %s, JoinColumn: %s, ", 
            _primary, getTableName(), _fieldName, getColumnName(), _joinTable, _joinColumn);
    }

}
