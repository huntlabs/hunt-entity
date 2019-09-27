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
import hunt.collection.ArrayList;
import hunt.collection.List;
import hunt.logging;
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
import hunt.entity.EntityException;
import hunt.sql.util.DBType;
import hunt.sql.SQLUtils;

import std.regex;
import std.format;

version(WITH_HUNT_TRACE)
{
    import hunt.trace.Constrants;
    import hunt.trace.Plugin;
    import hunt.trace.Span;
}

import std.algorithm;

deprecated("Using RowSet instead.")
alias ResultSet = RowSet;

class NativeQuery
{

    private string _nativeSql;
    private EntityManager _manager;
    private Object[int] _params;
    private Object[string] _parameters;
    private int _lastInsertId = -1;
    private int _affectRows = 0;

    version (WITH_HUNT_TRACE)
    {
        private Span _span;
        private string[string] _tags;
    }

    this(EntityManager manager, string sql)
    {
        _manager = manager;
        _nativeSql = sql;
    }

    version (WITH_HUNT_TRACE)
    {
        private void beginTrace(string name)
        {
            _tags.clear();
            _span = traceSpanBefore(name);
        }

        private void endTrace(string error = null)
        {
            if (_span !is null)
            {
                traceSpanAfter(_span, _tags, error);
            }
        }
    }

    public RowSet getResultList()
    {
        auto sql = paramedSql();
        version (WITH_HUNT_TRACE)
        {
            beginTrace("NativeQuery getResultList");
            scope (exit)
            {
                _tags["sql"] = sql;
                endTrace();
            }
        }
        auto stmt = _manager.getSession().prepare(sql);
        return stmt.query();
    }

    public int executeUpdate()
    {
        auto sql = paramedSql();
        version (WITH_HUNT_TRACE)
        {
            beginTrace("NativeQuery executeUpdate");
            scope (exit)
            {
                _tags["sql"] = sql;
                endTrace();
            }
        }
        auto stmt = _manager.getSession().prepare(sql);
        //TODO row line count is 0 for Update
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


    public void setParameter(R)(int idx, R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _params[idx] = new Integer(param);
        }
        else static if (is(R == char))
        {
            _params[idx] = new String(cast(string)[param]);
        }
        else static if (is(R == string))
        {
            _params[idx] = new String(param);
        }
        else static if(is(R == byte[]) || is(R == ubyte[])) {
            _params[idx] = new Bytes(cast(byte[])param);
        }
        else static if (is(R == bool))
        {
            _params[idx] = new Boolean(param);
        }
        else static if (is(R == double))
        {
            _params[idx] = new Double(param);
        }
        else static if (is(R == float))
        {
            _params[idx] = new Float(param);
        }
        else static if (is(R == short) || is(R == ushort))
        {
            _params[idx] = new Short(param);
        }
        else static if (is(R == long) || is(R == ulong))
        {
            _params[idx] = new Long(param);
        }
        else static if (is(R == byte) || is(R == ubyte))
        {
            _params[idx] = new Byte(param);
        }
        else static if (is(R == class))
        {
            _params[key] = param;
        }
        else
        {
            throw new EntityException("IllegalArgument not support : " ~ R.stringof);
        }
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
        else static if (is(R == class))
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
        version(HUNT_DEBUG) info(_nativeSql);

        string str = _nativeSql;
        foreach (k, v; _parameters)
        {
            auto re = regex(r":" ~ k ~ r"([^\w])", "g");
            if ((cast(String) v !is null) || (cast(Nullable!string) v !is null))
            {
                str = str.replaceAll(re, quoteSqlString(v.toString()) ~ "$1");
            }
            else
            {
                str = str.replaceAll(re, v.toString() ~ "$1");
            }
        }


        if (_params.length > 0)
        {
            auto keys = _params.keys;
            sort!("a < b")(keys);
            List!Object params = new ArrayList!Object();
            foreach (e; keys)
            {
                params.add(_params[e]);
            }

            auto opt = _manager.getDatabase().getOption();
            string dbtype;
            if (opt.isMysql())
            {
                dbtype = DBType.MYSQL.name;
            }
            else if (opt.isPgsql())
            {
                dbtype = DBType.POSTGRESQL.name;
            }
            // else if (opt.isSqlite())
            // {
            //     dbtype = DBType.SQLITE.name;

            // }
            else
            {
                throw new Exception("not support dbtype : %s".format(opt.schemeName()));
            }
                str = SQLUtils.format(str, DBType.MYSQL.name, params);
            }

        version(HUNT_DEBUG) info(str);
        return str;
    }

}
