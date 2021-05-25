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
 
module hunt.entity.Constant;

import hunt.String;
// import hunt.database;
import std.format;


struct Factory
{
    string name;
}

struct Table {
    string name;
    
    string prefix;
}

struct Column {
    string name;
    bool nullable = true;
}

struct JoinColumn {
    string name;
    string referencedColumnName;
    bool nullable = true;
}

struct JoinTable {
    string name;
}

// alias InverseJoinColumn = JoinColumn;
struct InverseJoinColumn {
    string name;
    string referencedColumnName;
    bool nullable = true;
}


struct OneToOne {
    string mappedBy;
    FetchType fetch = FetchType.EAGER;
    CascadeType cascade = CascadeType.ALL;
}


struct ManyToMany {
    string mappedBy;
    FetchType fetch = FetchType.LAZY;
    CascadeType cascade = CascadeType.ALL;
}


struct OneToMany {
    string mappedBy;
    FetchType fetch = FetchType.LAZY;
    CascadeType cascade = CascadeType.ALL;
} 


struct ManyToOne {
    FetchType fetch = FetchType.EAGER;
    CascadeType cascade = CascadeType.ALL;
} 

enum {
    Auto = 0x1,
    AutoIncrement = 0x1,
    Id = 0x2,
    Transient = 0x3
}

// deprecated("Using Id instead.")
alias PrimaryKey = Id;

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
    PERSIST, 
    REMOVE,  
    REFRESH, 
    MERGE,  
    ALL,      
}


class JoinSqlBuild  {
    string tableName;
    string joinWhere;
    JoinType joinType;
    string[] columnNames;

    override string toString()
    {
        return "(%s, %s, %s, %s)".format(tableName,joinWhere,joinType,columnNames);
    }
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

    override string toString()
    {
        return "(%s, %s)".format(key,value);
    }
}



