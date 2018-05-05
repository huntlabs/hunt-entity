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

//@TableName
struct Table {
    string name;
}

//@ColumnName
struct Column {
    string name;
}

//@JoinColumn
struct JoinColumn {
    string name;
}

struct PrimaryKeyJoinColumn {
    string name;
    string referencedColumnName;
}

//@OneToOne
struct OneToOne {
    FetchType fetch = FetchType.LAZY;
    CascadeType cascade = CascadeType.ALL;
}
//@OneToMany
struct ManyToMany {
    FetchType fetch = FetchType.LAZY;
    CascadeType cascade = CascadeType.ALL;
}
//@OneToMany
struct OneToMany {
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

struct JoinSqlBuild  {
    string tableName;
    string joinWhere;
    JoinType joinType;
    string[] columnNames;
}
