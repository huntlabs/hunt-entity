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
 
module entity.EntityManagerFactory;

import entity;
class EntityManagerFactory {

    public Dialect _dialect;
    public DatabaseConfig _config;
    public Database _db;
    public string _name;
    private CriteriaBuilder _criteriaBuilder;
    private string _dbPrefix;

    public this(string name, DatabaseConfig config, string tablePrefix = "") {
        _name = name;
        _config = config;
        _dbPrefix = tablePrefix;
        _db = new Database(config);
        _dialect = _db.createDialect();
        _criteriaBuilder = new CriteriaBuilder(this);
        autoCreateTables();
    }
    public EntityManager createEntityManager() {
        return new EntityManager(this, _name, _config, _db, _dialect);
    }
    public SqlBuilder createSqlBuilder() {
        return _db.createSqlBuilder();
    }
    
    public void close() {
        if (_db)
            _db.close();
        _db = null;
    }


    private string[] showTables() {
        string[] ret;
        SqlBuilder builder = createSqlBuilder();
        Statement stmt = _db.prepare(builder.showTables().build().toString());
        ResultSet rs = stmt.query();
        foreach(row; rs) {
            foreach(v; row.toStringArray()) {
                ret ~= v;
            }
        }
        return ret;
    }
    private string[] descTable(string tableName) {
        string[] ret;
        SqlBuilder builder = createSqlBuilder();
        Statement stmt = _db.prepare(builder.descTable(tableName).build().toString());
        ResultSet rs = stmt.query();
        foreach(row; rs) {
            string[string] array = row.toStringArray();
            ret ~= "Field" in array ? array["Field"] : array["field"];
        }
        return ret;
    }


    public void autoCreateTables() {
        string[] exsitTables = showTables();
        log("exsitTables= ", exsitTables);
        GetCreateTableHandle[string] flushList;

        foreach(k,v; __createTableList) {
            string check = _dbPrefix~k;
            log(" check = ", check);
            if (!Common.inArray(exsitTables, _dbPrefix~k)) {
                flushList[k] = v;
            }
        }

        string[] alterRows;
        //step1:create base table
        foreach(v;flushList) {
            string createSql = v(_dialect, _dbPrefix, alterRows);
            _db.execute(createSql);
        }
        
        //step2: alert table, eg add foreign key..
        foreach(v; alterRows) {
            log(v);
            _db.execute(v);
        }
        

    }

    public Dialect getDialect() {return _dialect;}
    public Database getDatabase() {return _db;}
    public CriteriaBuilder getCriteriaBuilder() {return _criteriaBuilder;}
    public string getDBPrefix() {return _dbPrefix;}

}

alias GetCreateTableHandle = string function(Dialect dialect, string tablePrefix, ref string[] alterRows);

string onCreateTableHandler(T)(Dialect dialect, string tablePrefix, ref string[] alertRows) {
    return (new EntityCreateTable!T).createTable(dialect, tablePrefix, alertRows);
}
void addCreateTableHandle(string tableName, GetCreateTableHandle handler) {
    __createTableList[tableName] = handler;
}
GetCreateTableHandle getCreateTableHandle(string tableName) {
    return __createTableList.get(tableName, null);
}
private:
__gshared GetCreateTableHandle[string] __createTableList;