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
 
module entity.Constant;

//@Factory
struct Factory
{
    string name;
}

//@TableName
struct Table {
    string name;
}

//@ColumnName
struct Column {
    string name;
    bool nullable = true;
}

//@JoinColumn
struct JoinColumn {
    string name;
    bool nullable = true;
}




//@OneToOne
struct OneToOne {
    FetchType fetch = FetchType.EAGER;
    string mappedBy;
    CascadeType cascade = CascadeType.ALL;
}
//@ManyToMany
struct ManyToMany {
    FetchType fetch = FetchType.LAZY;
    CascadeType cascade = CascadeType.ALL;
}
//@OneToMany
struct OneToMany {
    string mappedBy;
    FetchType fetch = FetchType.LAZY;
    CascadeType cascade = CascadeType.ALL;
} 
//@ManyToOne
struct ManyToOne {
    FetchType fetch = FetchType.EAGER;
    CascadeType cascade = CascadeType.ALL;
} 

enum {
    Auto = 0x1,
    AutoIncrement = 0x1,
    PrimaryKey = 0x2,
    Id = 0x4
}

enum OrderBy {
    ASC = 0,
    DESC = 1,
}
enum JoinType {
    INNER = 0,
    LEFT = 1,
    RIGHT = 2,
}
enum FetchType {
    LAZY,
    EAGER
}





enum CascadeType {
    PERSIST, //级联新建
    REMOVE,  //级联删除
    REFRESH, //级联刷新
    MERGE,   //级联更新 中选择一个或多个
    ALL,      //所有
}

//#fetch属性是该实体的加载方式，有两种：LAZY和EAGER。



class JoinSqlBuild  {
    string tableName;
    string joinWhere;
    JoinType joinType;
    string[] columnNames;
}

class ForeignKeyData {
    string columnName;
    string tableName;
    string primaryKey;
}


class LazyData {
    this(LazyData data) {
        key = data.key;
        value = data.value;
    }
    this(string key, string value) {
        this.key = key;
        this.value = value;
    }
    string key;
    string value;
}

class ColumnFieldData {
    string value;
    string valueType;
}



