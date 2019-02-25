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
 
module hunt.entity.NativeQuery;

import hunt.entity;
import hunt.Number;
import hunt.String;
import hunt.Integer;
import hunt.Long;
import hunt.Double;
import hunt.Float;
import hunt.Short;
import hunt.Byte;
import hunt.Boolean;
import hunt.Nullable;
import std.regex;
import hunt.entity.EntityException;

import hunt.trace.Constrants;
import hunt.trace.Plugin;
import hunt.trace.Span;

class NativeQuery {

    private string _nativeSql;
    private EntityManager _manager;
    private Object[string] _parameters;
    private int _lastInsertId = -1;
    private int _affectRows = 0;

    private Span _span;
    private string[string] _tags;

    this(EntityManager manager,string sql) {
        _manager = manager;
        _nativeSql = sql;
    }

    private void beginTrace(string name) {
        _tags.clear();
        _span = traceSpanBefore(name);
    }

    private void endTrace(string error = null) {
        if(_span !is null) {
            traceSpanAfter(_span , _tags , error);
        }
    }

    public ResultSet getResultList() {
        auto sql = paramedSql();
        beginTrace("NativeQuery getResultList");
        scope(exit){
            _tags["sql"] = sql;
            endTrace();
        }
        auto stmt = _manager.getSession().prepare(sql);
		return stmt.query();
    }

    public int executeUpdate() {
        auto sql = paramedSql();
        beginTrace("NativeQuery executeUpdate");
        scope(exit){
            _tags["sql"] = sql;
            endTrace();
        }
        auto stmt = _manager.getSession().prepare(sql); 
        //TODO update 时 返回的row line count 为 0
        _lastInsertId = stmt.lastInsertId();
        _affectRows = stmt.affectedRows();
        return stmt.execute();
    }

    public int lastInsertId()
    {
        return _lastInsertId;    
    }
    
	public int affectedRows()
    {
        return _affectRows;    
    }

    public void setParameter(R)(string key, R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _parameters[key] = new Integer(param);
        }
        else static if (is(R == string) || is(R == char) || is(R == byte[]))
        {
            _parameters[key] = new String(param);
        }
        else static if (is(R == bool))
        {
            _parameters[key] = new Boolean(param);
        }
        else static if (is(R == double))
        {
            _parameters[key] = new Double(param);
        }
        else static if (is(R == float))
        {
            _parameters[key] = new Float(param);
        }
        else static if (is(R == short) || is(R == ushort))
        {
            _parameters[key] = new Short(param);
        }
        else static if (is(R == long) || is(R == ulong))
        {
            _parameters[key] = new Long(param);
        }
        else static if (is(R == byte) || is(R == ubyte))
        {
            _parameters[key] = new Byte(param);
        }
        else static if(is(R == class))
        {
            _parameters[key] = param;
        }
        else
        {
            throw new EntityException("IllegalArgument not support : " ~ R.stringof);
        }
    }

    private string paramedSql()
    {
        string str = _nativeSql;
        foreach (k, v; _parameters)
        {
            auto re = regex(r":" ~ k ~ r"([^\w])", "g");
            if ((cast(String) v !is null) || (cast(Nullable!string)v !is null))
            {
                str = str.replaceAll(re, quoteSqlString(v.toString())  ~ "$1");
            }
            else
            {
                str = str.replaceAll(re, v.toString() ~ "$1" );
            }
        }
        return str;
    }

}
