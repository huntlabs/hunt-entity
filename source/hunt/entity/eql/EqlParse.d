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
import hunt.lang;
import hunt.database;
import std.algorithm.sorting;
import hunt.entity.eql.EqlInfo;
import std.regex;

void eql_throw(string type, string message) {
	throw new Exception("[EQL PARSE EXCEPTION." ~ type ~ "] " ~ message);
}

class EqlParse
{
    alias EntityField = EntityFieldInfo[string];
    private string _eql; 
    private string _parsedEql; 
    private string _dbtype;
    private ExportTableAliasVisitor _aliasVistor; //表 与 别名
    private SchemaStatVisitor   _schemaVistor;
    private List!SQLStatement _stmtList;
    private string[string] _clsNameToTbName;

    private EntityField[string] _tableFields;   //类名 与 表字段
    private EqlObject[string] _eqlObj;
    public  string[string] _objType;
    private  Object[string] _joinConds;

    private Object[int] _params;
    private Object[string] _parameters;


    this(string eql, string dbtype = "mysql")
    {
        _parsedEql = _eql = eql;
        _dbtype = dbtype;
        _aliasVistor = new ExportTableAliasVisitor();
        _schemaVistor = SQLUtils.createSchemaStatVisitor(_dbtype);
        // logDebug("EQL DBType : ",_dbtype);
    }

    string getEql()
    {
        return _eql;
    }

    string getDBType()
    {
        return _dbtype;
    }

    void setParsedEql(string parsedEql)
    {
        _parsedEql = parsedEql;
    }

    string getParsedEql()
    {
        return _parsedEql;
    }

    public void parse()
    {
        _stmtList = SQLUtils.parseStatements(_parsedEql, _dbtype);

        foreach(stmt ; _stmtList)
        {
            stmt.accept(_aliasVistor);
            stmt.accept(_schemaVistor);
        }

        if(_stmtList.size == 0)
            eql_throw("Statement", " statement error : " ~ _parsedEql);

        init();
    }

    private void init()
    {
        auto aliasMap = _aliasVistor.getAliasMap();
        foreach(objName , v ; aliasMap)
        {
            string clsName;
            auto expr = (cast(SQLExprTableSource)v).getExpr();
            if(cast(SQLIdentifierExpr)expr !is null)
            {
                clsName = (cast(SQLIdentifierExpr)expr).getName();
            }
            else if(cast(SQLPropertyExpr)expr !is null)
            {
                
                // clsName = (cast(SQLPropertyExpr)expr);
                clsName = _objType.get(convertExprAlias(cast(SQLPropertyExpr)expr),null);
            }
            auto obj = new EqlObject(objName , clsName);
            _eqlObj[objName] = obj;
        }

        foreach(objName , obj ; _eqlObj)
        {
            if(obj.className() != null)
            {
                auto tableName = _clsNameToTbName.get(obj.className(),null);
                if(tableName is null)
                {
                    eql_throw(obj.className(),"Class is not found");
                }
                obj.setTableName(tableName);
            }
        }

        // logDebug("aliasMap : %s".format(aliasMap));

        // logDebug("cls name : %s".format(_clsNameToTbName));

        // logDebug("EQL OBJS : %s".format(_eqlObj));

        // logDebug("EQL Conds : %s".format(_joinConds));

        // logDebug("EQL objType : %s".format(_objType));


        if(cast(SQLSelectStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_select_parse");
            doSelectParse();
        }
        else if(cast(SQLUpdateStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_update_parse");
            doUpdateParse();
        }
        else if(cast(SQLDeleteStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_delete_parse");
            doDeleteParse();
        }
        else
        {
            eql_throw("Statement", " unknown sql statement");
        }


        // logDebug("init eql : %s".format(_parsedEql));
    }

    private void doSelectParse()
    {
        auto queryBlock = (cast(SQLSelectStatement)(_stmtList.get(0))).getSelect().getQueryBlock();
        auto select_copy = queryBlock.clone();
        select_copy.getSelectList().clear();
        /// select item
        foreach(selectItem; queryBlock.getSelectList()) {
            auto expr = selectItem.getExpr();
            if(cast(SQLIdentifierExpr)expr !is null)
            {
                auto eqlObj = _eqlObj.get( (cast(SQLIdentifierExpr)expr).getName(),null);
                if(eqlObj !is null)
                {
                    auto clsName = eqlObj.className();
                    auto fields = _tableFields.get(clsName,null);
                    if(fields !is null)
                    {
                        foreach(clsFiled , entFiled ; fields)
                        {
                            if(!(clsName ~ "." ~ clsFiled in _objType)) /// ordinary member
                            {
                                select_copy.addSelectItem(new SQLIdentifierExpr(selectItem.getAlias() is null ? entFiled.getSelectColumn() : entFiled.getFullColumn()),selectItem.getAlias());
                                // logDebug("sql replace : (%s ,%s) ".format(clsName ~ "." ~ clsFiled,clsName ~ "." ~ entFiled.getSelectColumn()));
                            }
                        }
                    }
                }
            }
            else if(cast(SQLPropertyExpr)expr !is null)
            {
                auto eqlObj = _eqlObj.get( (cast(SQLPropertyExpr)expr).getOwnernName(),null);
                auto clsFieldName = (cast(SQLPropertyExpr)expr).getName();
                if(eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(),null);
                    if(fields !is null)
                    {
                        foreach(clsFiled , entFiled ; fields)
                        {
                            if(clsFiled == clsFieldName)
                            {
                                select_copy.addSelectItem(new SQLIdentifierExpr(selectItem.getAlias() is null ? entFiled.getSelectColumn() : entFiled.getFullColumn()),selectItem.getAlias());
                                break;
                            }
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                        }
                    }
                }
            }
            else
            {
                // logError("------> :",SQLUtils.toSQLString(selectItem));
                select_copy.addSelectItem(selectItem);
            }
        }

        ///from
        auto fromExpr = select_copy.getFrom();
        parseFromTable(fromExpr);

        ///where 
        auto whereCond = select_copy.getWhere();
        if(whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            select_copy.setWhere(SQLUtils.toSQLExpr(where));
        }

        ///order by
        auto orderBy = select_copy.getOrderBy();
        if(orderBy !is null)
        {
            foreach(item ; orderBy.getItems)
            {
                auto exprStr = SQLUtils.toSQLString(item.getExpr(),_dbtype);
                // logDebug("order item : %s".format(exprStr));
                item.replace(item.getExpr(),SQLUtils.toSQLExpr(convertAttrExpr(exprStr),_dbtype));
            }
        }

        /// group by 
        auto groupBy = select_copy.getGroupBy();
        if(groupBy !is null)
        {
            groupBy.getItems().clear();
            foreach(item ; queryBlock.getGroupBy().getItems())
            {
                // logDebug("group item : %s".format(SQLUtils.toSQLString(item)));
                groupBy.addItem(SQLUtils.toSQLExpr(convertAttrExpr(SQLUtils.toSQLString(item))));
            }
            auto having = groupBy.getHaving();
            if(having !is null)
            {
                groupBy.setHaving(SQLUtils.toSQLExpr(convertAttrExpr(SQLUtils.toSQLString(having))));
            }
            select_copy.setGroupBy(groupBy);
        }

        _parsedEql = SQLUtils.toSQLString(select_copy,_dbtype);

    }

    private void doUpdateParse()
    {
        auto updateBlock = cast(SQLUpdateStatement)(_stmtList.get(0));
        /// update item
        foreach(updateItem; updateBlock.getItems()) {
            // logDebug("clone selcet : ( %s , %s ) ".format(SQLUtils.toSQLString(selectItem.getExpr()),selectItem.computeAlias()));
            auto expr = updateItem.getColumn();
            if(cast(SQLIdentifierExpr)expr !is null)
            {
                
            }
            if(cast(SQLPropertyExpr)expr !is null)
            {
                auto eqlObj = _eqlObj.get( (cast(SQLPropertyExpr)expr).getOwnernName(),null);
                auto clsFieldName = (cast(SQLPropertyExpr)expr).getName();
                if(eqlObj !is null)
                {
                    auto fields = _tableFields.get(eqlObj.className(),null);
                    if(fields !is null)
                    {
                        foreach(clsFiled , entFiled ; fields)
                        {
                            if(clsFiled == clsFieldName)
                            {
                                updateItem.setColumn(new SQLPropertyExpr(eqlObj.tableName(),entFiled.getColumnName()));
                                break;
                            }
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ clsFiled,k ~ "." ~ entFiled.getColumnName()));
                        }
                    }
                }
            }
        }

        ///from
        auto fromExpr = updateBlock.getTableSource();
        // logDebug("update From : %s".format(SQLUtils.toSQLString(fromExpr)));
        parseFromTable(fromExpr);

        ///where 
        auto whereCond = updateBlock.getWhere();
        if(whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            updateBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _parsedEql = SQLUtils.toSQLString(updateBlock,_dbtype);
    }

    private void doDeleteParse()
    {
        auto delBlock = cast(SQLDeleteStatement)(_stmtList.get(0));

        
        ///from
        auto fromExpr = delBlock.getTableSource();
        // logDebug("delete From : %s".format(SQLUtils.toSQLString(fromExpr)));

        parseFromTable(fromExpr);

        ///where 
        auto whereCond = delBlock.getWhere();
        if(whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            delBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _parsedEql = SQLUtils.toSQLString(delBlock,_dbtype);
    }

    /// a.id  --- > Class.id , a is instance of Class
    private string convertExprAlias(SQLPropertyExpr expr)
    {
        string originStr = SQLUtils.toSQLString(expr) ;
        auto objName = expr.getOwnernName();
        auto subPropertyName = expr.getName();
        auto aliasMap = _aliasVistor.getAliasMap();
        string clsName;
        foreach(obj , v ; aliasMap)
        {
            if(obj == objName)
            {
                auto exprTab = (cast(SQLExprTableSource)v).getExpr();
                if(cast(SQLIdentifierExpr)exprTab !is null)
                {
                    expr.setOwner(exprTab);
                }
                else if(cast(SQLPropertyExpr)exprTab !is null)
                {
                    expr.setOwner(SQLUtils.toSQLExpr(convertExprAlias(cast(SQLPropertyExpr)exprTab)));
                }
            }
        }
        // logDebug("get last type : ( %s , %s )".format(originStr,SQLUtils.toSQLString(expr)));
        return SQLUtils.toSQLString(expr);
    }

    /// a.id --> Table.col
    private string convertAttrExpr(string attrExpr)
    {
        string res = attrExpr;
        auto conds = matchAll(attrExpr, regex("([^\\s]+)\\.([^\\s]+)"));
        foreach(cond ; conds)
        {
            string newCond = cond.captures[0];
            auto eqlObj = _eqlObj.get(cond.captures[1],null);
            if(eqlObj !is null)
            {
                newCond = newCond.replace(cond.captures[1]~".",eqlObj.tableName()~".");
                auto fields = _tableFields.get(eqlObj.className(),null);
                if(fields !is null)
                {
                    foreach(clsFiled , entFiled ; fields)
                    {
                        if(clsFiled == cond.captures[2])
                            newCond = newCond.replace("."~cond.captures[2],"."~entFiled.getColumnName());
                       
                    }
                }
            }
            res = res.replace(cond.captures[0],newCond);
        }
        return res;
    }

    /// remove alias & a.xx -- > Table
    private void parseFromTable(SQLTableSource fromExpr)
    {
        if(fromExpr is null)
        {
            eql_throw("Table","no found table");
        }
        // logDebug(" From table : %s".format(SQLUtils.toSQLString(fromExpr)));
        if(cast(SQLJoinTableSource)fromExpr !is null)
        {
            auto joinExpr = cast(SQLJoinTableSource)fromExpr;
            auto rightExpr = cast(SQLExprTableSource)(joinExpr.getRight());
            
            auto defaultJoinCond = joinExpr.getCondition();
            if(defaultJoinCond is null)
            {
                // logDebug("join table no default condition");
            }
            else
            {
                auto convertAttrStr = convertAttrExpr(SQLUtils.toSQLString(defaultJoinCond));
                // logDebug(" join Cond : %s , convert : %s ".format(SQLUtils.toSQLString(defaultJoinCond),convertAttrStr));
                joinExpr.setCondition(SQLUtils.toSQLExpr(convertAttrStr));
            }

            if(cast(SQLJoinTableSource)(joinExpr.getLeft()) !is null)
            {
                auto subExpr = cast(SQLJoinTableSource)(joinExpr.getLeft());
                parseFromTable(subExpr);
            }
            else if(cast(SQLExprTableSource)(joinExpr.getLeft()) !is null)
            {
                auto leftExpr = cast(SQLExprTableSource)(joinExpr.getLeft());

                if(cast(SQLPropertyExpr)(leftExpr.getExpr()) !is null)
                {
                    auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(leftExpr.getExpr()));
                    auto clsName = _objType.get(convertStr,null);
                    if(clsName !is null)
                    {
                        auto tableName = _clsNameToTbName.get(clsName,null);
                        if(tableName !is null)
                        {
                            leftExpr.setExpr(tableName);
                        }
                    }
                    auto joinCond = _joinConds.get(convertStr,null);
                        // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));
                    if(joinCond !is null)
                    {
                        joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond.toString()));
                    }
                }
                else if(cast(SQLIdentifierExpr)(leftExpr.getExpr()) !is null)
                {
                    auto clsName = (cast(SQLIdentifierExpr)(leftExpr.getExpr())).getName();
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        leftExpr.setExpr(tableName);
                    }
                }
                leftExpr.setAlias("");
            }

            
            if(rightExpr is null)
                return;
            if(cast(SQLPropertyExpr)(rightExpr.getExpr()) !is null)
            {
                auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(rightExpr.getExpr()));
                auto clsName = _objType.get(convertStr,null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        rightExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(convertStr,null);
                    // logDebug("add cond : ( %s , %s )".format(clsName,joinCond));

                if(joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond.toString()));
                }
            }
            else if(cast(SQLIdentifierExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(rightExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    rightExpr.setExpr(tableName);
                }
            }

            rightExpr.setAlias("");
        }
        else
        {
            auto expr = cast(SQLExprTableSource)(fromExpr);
            if(expr is null)
                return;
            if(cast(SQLPropertyExpr)(expr.getExpr()) !is null)
            {
                auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(expr.getExpr()));
                auto clsName = _objType.get(convertStr,null);
                if(clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName,null);
                    if(tableName !is null)
                    {
                        expr.setExpr(tableName);
                    }
                }
                
            }
            else if(cast(SQLIdentifierExpr)(expr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(expr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName,null);
                if(tableName !is null)
                {
                    expr.setExpr(tableName);
                }
            }
            expr.setAlias("");
        }
    }

    public void setParameter(R)(int idx , R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _params[idx] = new Integer(param);
        }
        else static if(is( R == string ) || is ( R == char ) || is( R == byte[] ))
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
        else static if(is(R == class))
        {
            _params[key] = param;
        }
        else
        {
            eql_throw("setParameter","IllegalArgument not support : " ~ R.stringof);
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
        else static if(is(R == class))
        {
            _parameters[key] = param;
        }
        else
        {
            eql_throw("setParameter","IllegalArgument not support : " ~ R.stringof);
        }
    }

    public void putClsTbName(string clsName, string tableName)
    {
        _clsNameToTbName[clsName] = tableName;
    }

    public void putFields(string table, EntityField ef)
    {
        _tableFields[table] = ef;
    }

    public void putJoinCond(Object[string] conds)
    {
        foreach(k , v; conds) {
            _joinConds[k] = v;
        }
    }

    public string getTableName(string clsName)
    {
        return _clsNameToTbName.get(clsName,null);
    }

    public string getNativeSql()
    {
        string sql = _parsedEql;

        version(HUNT_DEBUG) logDebug("EQL params : ",_parameters);

        foreach (k, v; _parameters)
        {
            auto re = regex(r":" ~ k ~ r"([^\w]*)", "g");
            if (cast(String) v !is null || (cast(Nullable!string)v !is null))
            {
                sql = sql.replaceAll(re,quoteSqlString(v.toString())  ~ "$1");
            }
            else
            {
                sql = sql.replaceAll(re, v.toString() ~ "$1" );
            }
        }

        if(_params.length > 0)
        {
            auto keys = _params.keys;
            sort!("a < b")(keys);
            List!Object params = new ArrayList!Object();
            foreach(e;keys)
            {
                params.add(_params[e]);
            }
            sql = SQLUtils.format(sql, _dbtype,params);
        }
       

        // logDebug("native sql : %s".format(sql));
        return sql;
    }
}