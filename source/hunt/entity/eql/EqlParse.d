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
 
module hunt.entity.eql.EqlParse;

import hunt.entity;
import hunt.sql;
import hunt.logging;
import hunt.container;

class EqlParse
{
    alias EntityField = EntityFieldInfo[string];
    private string _eql;
    private string _dbtype;
    private ExportTableAliasVisitor _aliasVistor;
    private SchemaStatVisitor   _schemaVistor;
    List!SQLStatement _stmtList;
    private string[string] _clsNameToTbName;

    EntityField[string] _tableFields;

    this(string eql, string dbtype = "mysql")
    {
        _eql = eql;
        _dbtype = dbtype;
        _aliasVistor = new ExportTableAliasVisitor();
        _schemaVistor = SQLUtils.createSchemaStatVisitor(_dbtype);
    }

    void parse()
    {
        _stmtList = SQLUtils.parseStatements(_eql, _dbtype);

        foreach(stmt ; _stmtList)
        {
            stmt.accept(_aliasVistor);
            stmt.accept(_schemaVistor);
        }
    }

    void putClsTbName(string clsName, string tableName)
    {
        _clsNameToTbName[clsName] = tableName;
    }

    void putFields(string table, EntityField ef)
    {
        _tableFields[table] = ef;
    }

    string getTableName(string clsName)
    {
        return _clsNameToTbName.get(clsName,null);
    }

    string getNativeSql()
    {
        string sql = _eql;
         auto aliasMap = _aliasVistor.getAliasMap();
         foreach(k ,v ; _tableFields)
         {
             foreach(col , fild ; v)
             {
                 sql = sql.replace(col,fild.getColumnName());
             }
         }
        //  foreach(k,v; aliasMap)
        //  {
        //     logDebug("alisMap : (%s ,%s) ".format(k,SQLUtils.toSQLString(v));
        //  }
        //  foreach(col; _schemaVistor.getColumns()) {
        //     logDebug("column : %s , isSelectItem : %s ".format(col.getFullName(),col.isSelect()));
        // }
        foreach(clsName , tbName ; _clsNameToTbName)
        {
            sql = sql.replace(" "~ clsName ~ " "," "~ tbName ~ " ");
        }
        return sql;
    }
}