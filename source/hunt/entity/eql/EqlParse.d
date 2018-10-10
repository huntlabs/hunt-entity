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
import hunt.math;
import std.algorithm.sorting;

class EqlParse
{
    alias EntityField = EntityFieldInfo[string];
    private string _eql;
    private string _dbtype;
    private ExportTableAliasVisitor _aliasVistor; //表 与 别名
    private SchemaStatVisitor   _schemaVistor;
    private List!SQLStatement _stmtList;
    private string[string] _clsNameToTbName;

    EntityField[string] _tableFields;   //类名 与 表字段

    Object[int] _params;

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
    
    void setParameter(R)(int idx , R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _params[idx] = new Integer(param);
        }
        else static if(is( R == string))
        {
            _params[idx] = new String(param);
        }
        else static if(is( R == bool))
        {
            _params[idx] = new Boolean(param);
        }
        else static if(is( R == double))
        {
            _params[idx] = new Double(param);
        }
        else static if(is( R == float))
        {
            _params[idx] = new Float(param);
        }
        else static if(is( R == short) || is( R == ushort))
        {
            _params[idx] = new Short(param);
        }
        else static if(is( R == long) || is( R == ulong))
        {
            _params[idx] = new Long(param);
        }
        else static if(is(R == byte) || is(R == ubyte))
        {
            _params[idx] = new Byte(param);
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

        foreach(k,v; aliasMap)
        {
            auto clsName = (cast(SQLExprTableSource)v).getName().getSimpleName();
            auto tableField = _tableFields.get(clsName,null);
            if(tableField != null)
            {
                foreach(clsFiled , entFiled ; tableField)
                {
                    sql = sql.replace(k ~ "." ~ clsFiled , k ~ "." ~ entFiled.getColumnName());
                    // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                }
            }
        }
  
        foreach(clsName , tbName ; _clsNameToTbName)
        {
            sql = sql.replace(" "~ clsName ~ " "," "~ tbName ~ " ");
        }
        auto keys = _params.keys;
		sort!("a < b")(keys);
        List!Object params = new ArrayList!Object();
		foreach(e;keys)
        {
            params.add(_params[e]);
        }
        sql = SQLUtils.format(sql, DBType.ORACLE.name,params);
        return sql;
    }
}