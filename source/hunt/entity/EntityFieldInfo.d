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

class EntityFieldInfo : EntityExpression
{
    private string _fileldName;
    protected string _joinColumn;
    protected string _joinTable;
    protected string _joinPrimaryKey;
    protected ForeignKeyData _foreignKeyData;
    protected JoinSqlBuild _joinSqlData;
    protected ColumnFieldData _columnFieldData;
 
    protected bool _enableJoin = true;
    private bool _nullable = true;
    private bool _primary;
    private bool _auto;
    



    public this(string fileldName, string columnName, string tableName) {
        super(columnName, tableName);
        _fileldName = fileldName;
    }



    public void setNullable(bool b) {_nullable = b;}
    public bool getNullable() {return _nullable;}
    public void setPrimary(bool b) {_primary = b;}
    public bool getPrimary() {return _primary;}
    public void setAuto(bool b) {_auto = b;}
    public bool getAuto() {return _auto;}




    public string getFileldName() {return _fileldName;}
    public string getJoinColumn() {return _joinColumn;}
    public string getJoinTable() {return _joinTable;}
    public string getJoinPrimaryKey() {return _joinPrimaryKey;}
    public ForeignKeyData getForeignKeyData() {return _foreignKeyData;}

    public JoinSqlBuild getJoinSqlData() {return _joinSqlData;}
    public bool isEnableJoin() {return _enableJoin;}
    public ColumnFieldData getColumnFieldData() {return _columnFieldData;}

}
