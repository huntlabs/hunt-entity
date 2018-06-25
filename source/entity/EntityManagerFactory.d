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
import entity.EntityOption;

class EntityManagerFactory {

    public Dialect _dialect;
    public EntityOption _option;
    public Database _db;
    public string _name;
    private CriteriaBuilder _criteriaBuilder;
    private string[] _exitTables;

    public this(string name, EntityOption option)
    {
        _name = name;
        _option = option;
        
        auto databaseOptions = new DatabaseOption(_option.database.url);
        databaseOptions.setMaximumConnection(_option.pool.maxConnection);
        databaseOptions.setMinimumConnection(_option.pool.minConnection);
        databaseOptions.setConnectionTimeout(_option.pool.connectionTimeout);

        _db = new Database(databaseOptions);
        _dialect = _db.createDialect();
        _criteriaBuilder = new CriteriaBuilder(this);
        _exitTables = showTables();
        autoCreateTables();
    }
    
    public EntityManager createEntityManager()
    {
        return new EntityManager(this, _name, _option, _db, _dialect);
    }

    public SqlBuilder createSqlBuilder()
    {
        return _db.createSqlBuilder();
    }
    
    public void close()
    {
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

    private string[] descTable(string tableName)
    {
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

    public static void prepareEntity(T...)() {
        foreach(V; T) {
            addCreateTableHandle(getEntityTableName!V, &onCreateTableHandler!V);
        }
    }

    public void createTables(T...)() {
        prepareEntity!(T);
        autoCreateTables();
    }

    public void autoCreateTables()
    {
        GetCreateTableHandle[string] flushList;
        foreach(k,v; __createTableList) {
            string check = _option.database.prefix~k;
            if (!Common.inArray(_exitTables, _option.database.prefix~k)) {
                flushList[k] = v;
                log("create new table ", _option.database.prefix~k);
            }
        }

        string[] alterRows;
        //step1:create base table
        foreach(v;flushList) {
            string createSql = v(_dialect, _option.database.prefix, alterRows);
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
}



alias GetCreateTableHandle = string function(Dialect dialect, string tablePrefix, ref string[] alterRows);
string onCreateTableHandler(T)(Dialect dialect, string tablePrefix, ref string[] alertRows)
{
    return (new EntityCreateTable!T).createTable(dialect, tablePrefix, alertRows);
}
void addCreateTableHandle(string tableName, GetCreateTableHandle handler)
{
    if (tableName !in __createTableList)
        __createTableList[tableName] = handler;
}
GetCreateTableHandle getCreateTableHandle(string tableName)
{
    return __createTableList.get(tableName, null);
}
string getEntityTableName(T)() {
    static if (hasUDA!(T, Table)) {
        return getUDAs!(getSymbolsByUDA!(T,Table)[0], Table)[0].name;
    }
    else {
        return T.stringof;
    }
}
private:
__gshared GetCreateTableHandle[string] __createTableList;