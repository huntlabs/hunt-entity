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
 
module hunt.entity.EntityExpression;

import std.string;

class EntityExpression
{
    private string _columnName;
    private string _columnSpecifier;
    private string _tableName;

    private string _fullColumn;
    private string _selectColumn;
    private string _columnAs;

    this(string columnName, string tableName)
    {
        _columnName = columnName;
        _tableName = tableName;
        _fullColumn = tableName ~ "." ~ columnName;
        _columnAs = tableName ~ "__as__" ~ columnName;
        _selectColumn = _fullColumn ~ " AS " ~ _columnAs;
    }

    public string getFullColumn() {return _fullColumn;}
    public string getColumnName() {return _columnName;}
    public string getTableName() {return _tableName;}
    public string getColumnAs() {return _selectColumn;}
    public string getColumnAsName() {return _columnAs;}

    public string getSelectColumn()
    {
        return _fullColumn ~ " AS " ~ _columnAs;
    }

    //s: max min avg sum count
    public EntityExpression setColumnSpecifier(string s)
    {
        _fullColumn = s ~ "(" ~ _fullColumn ~ ")";
        if (s == "COUNT" || s == "count") {
            _columnAs = _tableName ~ "__as__countfor"~_tableName~"_";
        }
        return this;
    }

    public EntityExpression setDistinct(bool b)
    {
        if (b)
            _fullColumn = "DISTINCT "~_fullColumn;
        else 
            _fullColumn = _fullColumn.replace("DISTINCT ", "");
        return this;
    } 


    static string getFullColumnName(string columnName, string tableName) {
        return tableName ~ "." ~ columnName;
    }

    static string getColumnAsName(string columnName, string tableName) {
        return tableName ~ "__as__" ~ columnName;
    }

    static string getColumnAs(string columnName, string tableName) {
        return getFullColumnName(columnName, tableName) ~ " AS " ~ getColumnAsName(columnName, tableName);
    }    
}
