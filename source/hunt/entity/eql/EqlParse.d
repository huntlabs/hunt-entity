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

import hunt.entity.eql.EqlInfo;
import hunt.entity;
import hunt.entity.EntityMetaInfo;
import hunt.sql;

import hunt.logging;
import hunt.collection;
import hunt.math;
import hunt.Number;
import hunt.String;
import hunt.Integer;
import hunt.Long;
import hunt.Double;
import hunt.Float;
import hunt.Short;
import hunt.Byte;
import hunt.Boolean;
import hunt.database;
import hunt.Nullable;

import std.algorithm.sorting;
import std.format;
import std.regex;
import std.string;

void eql_throw(string type, string message) {
    throw new Exception("[EQL PARSE EXCEPTION. " ~ type ~ "] " ~ message);
}

/**
 * 
 */
private class EqlSubstitutionContext {
    // EqlObject[string] eqlObjs;
    // The key is the name of a model.
    EntityFieldInfo[string][string] tableFields;

    string[string] modelTableMap;
    string[string] aliasModelMap;

    string getTableByModel(string name, string defaultValue) {
        auto itemPtr = name in modelTableMap;
        if(itemPtr is null) {
            version (HUNT_ENTITY_DEBUG) warningf("Can't find the table name for a mode: %s", name);
            return defaultValue;
        } else {
            return *itemPtr;
        }
    }

    string getModelByAlias(string name, string defaultValue) {
        auto itemPtr = name in aliasModelMap;
        if(itemPtr is null) {
            version (HUNT_ENTITY_DEBUG) warningf("Can't find the model name for an alias: %s", name);
            return defaultValue;
        } else {
            return *itemPtr;
        }
    }
}

/**
 * 
 */
class EqlParse {
    alias EntityField = EntityFieldInfo[string];
    private string _eql;
    private string _parsedEql;
    private string _dbtype;
    private ExportTableAliasVisitor _aliasVistor; //Table and alias
    private SchemaStatVisitor _schemaVistor;
    private List!SQLStatement _stmtList;
    private string[string] _clsNameToTbName;

    private EntityField[string] _tableFields; //Class name and field name
    private EqlObject[string] _eqlObj;
    public string[string] _objType;
    private Object[string] _joinConds;

    private Object[int] _params;
    private Object[string] _parameters;

    private EntityMetaInfo _entityInfo;
    private FormatOption _formatOption;
    private string _nativeSql;

    this(string eql, ref EntityMetaInfo entityInfo, string dbtype = "mysql")
    {
        _entityInfo = entityInfo;
        _parsedEql = _eql = eql;
        _dbtype = dbtype;
        _aliasVistor = new ExportTableAliasVisitor();
        _schemaVistor = SQLUtils.createSchemaStatVisitor(_dbtype);

        _formatOption = new FormatOption(true, true);
        _formatOption.config(VisitorFeature.OutputQuotedIdentifier, true);
    }

    FormatOption formatOption() {
        return _formatOption;
    }

    void formatOption(FormatOption value) {
        _formatOption = value;
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
        try
        {
            // version(HUNT_DEBUG)logInfo("-----> :",_parsedEql);
            _stmtList = SQLUtils.parseStatements(_parsedEql, _dbtype);

            foreach (stmt; _stmtList)
            {
                stmt.accept(_aliasVistor);
                stmt.accept(_schemaVistor);
            }

            if (_stmtList.size == 0)
                eql_throw("Statement", " statement error : " ~ _parsedEql);

            init();
        }
        catch (Exception e)
        {
            throw e;
        }

    }

    private void init()
    {
        version(HUNT_ENTITY_DEBUG) {
            tracef("_objType: %s", _objType);
        }

        _nativeSql = "";
        Map!(string, SQLTableSource) aliasMap = _aliasVistor.getAliasMap();
        foreach (string objName, SQLTableSource v; aliasMap)
        {
            string clsName;
            SQLExpr expr = (cast(SQLExprTableSource) v).getExpr();
            if (cast(SQLIdentifierExpr) expr !is null)
            {
                clsName = (cast(SQLIdentifierExpr) expr).getName();
            }
            else if (cast(SQLPropertyExpr) expr !is null)
            {
                // clsName = (cast(SQLPropertyExpr)expr);
                clsName = _objType.get(convertExprAlias(cast(SQLPropertyExpr) expr), null);
            } else {
                version(HUNT_ENTITY_DEBUG) {
                    warningf("Unhandled expression: %s", typeid(cast(Object)expr));
                }
            }

            if(clsName.empty() || objName.empty()) {
                version(HUNT_ENTITY_DEBUG) {
                    warningf("clsName: %s, objName: %s", clsName, objName);
                }
                continue;
            }

            auto obj = new EqlObject(objName, clsName);
            _eqlObj[objName] = obj;
        }

        version (HUNT_ENTITY_DEBUG) {
            trace(_clsNameToTbName);
        }

        foreach (string objName, EqlObject obj; _eqlObj)
        {
            string className = obj.className();
            if(className.empty()) {
                warningf("className is empty for %s", objName);
                continue;
            }
            // assert(!className.empty());

            string tableName = _clsNameToTbName.get(className, null);
            if (tableName.empty()) {
                eql_throw(className, "table is not found");
            }
            obj.setTableName(tableName);
        }

        // logDebug("aliasMap : %s".format(aliasMap));

        // logDebug("cls name : %s".format(_clsNameToTbName));

        // logDebug("EQL OBJS : %s".format(_eqlObj));

        // logDebug("EQL Conds : %s".format(_joinConds));

        // logDebug("EQL objType : %s".format(_objType));

        if (cast(SQLSelectStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_select_parse");
            doSelectParse();
        }
        else if (cast(SQLUpdateStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_update_parse");
            doUpdateParse();
        }
        else if (cast(SQLDeleteStatement)(_stmtList.get(0)) !is null)
        {
            // logDebug("EQL do_delete_parse");
            doDeleteParse();
        }
        else if (cast(SQLInsertStatement)(_stmtList.get(0)) !is null)
        {
            version (HUNT_ENTITY_DEBUG_MORE)
                logDebug("EQL do_insert_parse");
            doInsertParse();
        }
        else
        {
            eql_throw("Statement",
                    " unknown sql statement : " ~ typeid(cast(Object)(_stmtList.get(0))).toString);
        }

        // logDebug("init eql : %s".format(_parsedEql));
    }

    private void doSelectParse()
    {
        auto queryBlock = (cast(SQLSelectStatement)(_stmtList.get(0))).getSelect().getQueryBlock();
        auto select_copy = queryBlock.clone();
        select_copy.getSelectList().clear();
        /// select item
        foreach (selectItem; queryBlock.getSelectList())
        {
            auto expr = selectItem.getExpr();
            
            Object oo = cast(Object)expr;
            // version(HUNT_DEBUG) infof("Expr: %s, item: %s", typeid(oo).name, SQLUtils.toSQLString(selectItem));
            version(HUNT_ENTITY_DEBUG) infof("Expr: %s", typeid(oo).name);

            if (cast(SQLIdentifierExpr) expr !is null)
            {
                auto eqlObj = _eqlObj.get((cast(SQLIdentifierExpr) expr).getName(), null);
                if (eqlObj !is null)
                {
                    auto clsName = eqlObj.className();
                    EntityFieldInfo[string] fields = _tableFields.get(clsName, null);

                    if (fields !is null)
                    {
                        foreach (string classMember, EntityFieldInfo fieldInfo; fields)
                        {
                            if(fieldInfo.isAggregateType()) {
                                // ignore all the aggregative members;
                                version(HUNT_DEBUG) {
                                    infof("Aggregative member ignored: %s", classMember);
                                }

                                continue;
                            }

                            if (!(clsName ~ "." ~ classMember in _objType)) /// ordinary member
                            {
                                string columnAlias = selectItem.getAlias();

                                version(HUNT_ENTITY_DEBUG) {
                                    tracef("columnAlias: [%s], SelectColumn: [%s], fullColumn: [%s]", 
                                        columnAlias, fieldInfo.getSelectColumn(), fieldInfo.getFullColumn());
                                }

                                // SQLIdentifierExpr identifierExpr = new SQLIdentifierExpr(fieldInfo.getFullColumn());                                    

                                SQLIdentifierExpr identifierExpr = new SQLIdentifierExpr(columnAlias.empty()
                                        ? fieldInfo.getSelectColumn()
                                        : fieldInfo.getFullColumn());

                                select_copy.addSelectItem(identifierExpr, columnAlias);
                                // logDebug("sql replace : (%s ,%s) ".format(clsName ~ "." ~ classMember,clsName ~ "." ~ fieldInfo.getSelectColumn()));
                            }
                        }
                    }
                }
            }
            else if (cast(SQLPropertyExpr) expr !is null)
            {
                auto eqlObj = _eqlObj.get((cast(SQLPropertyExpr) expr).getOwnernName(), null);
                auto currentFieldName = (cast(SQLPropertyExpr) expr).getName();
                if (eqlObj !is null)
                {
                    bool isHandled = false;
                    auto fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (string classMember, EntityFieldInfo fieldInfo; fields) {
                            string columnName = fieldInfo.getColumnName();
                            version(HUNT_ENTITY_DEBUG_MORE) {
                                tracef("classMember: %s, columnName: %s, currentField: %s", 
                                    classMember, columnName, currentFieldName);
                            }
                            isHandled = classMember == currentFieldName || columnName == currentFieldName;
                            if (isHandled)
                            {
                                select_copy.addSelectItem(new SQLIdentifierExpr(selectItem.getAlias() is null
                                        ? fieldInfo.getSelectColumn()
                                        : fieldInfo.getFullColumn()), selectItem.getAlias());
                                break;
                            }
                            // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ classMember,k ~ "." ~ fieldInfo.getColumnName()));
                        }
                    }

                    if(!isHandled) {
                        string msg = format("Found a undefined memeber [%s] in class [%s]", 
                            currentFieldName, eqlObj.className());
                        warningf(msg);

                        // TODO: Tasks pending completion -@zhangxueping at 2020-10-20T14:32:17+08:00
                        // 
                        // throw new EntityException(msg);
                    }                    
                }
                else
                {
                    eql_throw("Statement",
                    " undefined sql object  '%s' in '%s': ".format((cast(SQLPropertyExpr) expr).getOwnernName(),SQLUtils.toSQLString(expr)));
                }
            }
            else if (cast(SQLAggregateExpr) expr !is null)
            {
                SQLAggregateExpr aggreExpr = cast(SQLAggregateExpr) expr;
                List!SQLExpr newArgs = new ArrayList!SQLExpr();
                foreach (subExpr; aggreExpr.getArguments())
                {
                    // version(HUNT_ENTITY_DEBUG_MORE) {
                    //     tracef("arg expr : %s, arg string : %s",
                    //         typeid(cast(Object)subExpr).name, SQLUtils.toSQLString(subExpr));
                    // }

                    if (cast(SQLIdentifierExpr) subExpr !is null)
                    {
                        newArgs.add(subExpr);
                    }
                    else if (cast(SQLPropertyExpr) subExpr !is null)
                    {
                        SQLPropertyExpr pExpr = cast(SQLPropertyExpr) subExpr;
                        auto eqlObj = _eqlObj.get(pExpr.getOwnernName(), null);
                        auto currentFieldName = (cast(SQLPropertyExpr) subExpr).getName();
                        if (eqlObj !is null)
                        {
                            bool isHandled = false;
                            auto fields = _tableFields.get(eqlObj.className(), null);
                            if (fields !is null)
                            {
                                foreach (string classMember, EntityFieldInfo fieldInfo; fields)
                                {
                                    string columnName = fieldInfo.getColumnName();

                                    version(HUNT_ENTITY_DEBUG_MORE) {
                                        tracef("classMember: %s, columnName: %s, currentField: %s", 
                                            classMember, columnName, currentFieldName);
                                    }

                                    isHandled = classMember == currentFieldName || columnName == currentFieldName;
                                    if (isHandled)
                                    {
                                        newArgs.add(new SQLPropertyExpr(eqlObj.tableName(),
                                                fieldInfo.getColumnName()));
                                        break;
                                    }
                                }
                            }
                        
                            if(!isHandled) {
                                string msg = format("Found a undefined memeber [%s] in class [%s]", 
                                    currentFieldName, eqlObj.className());
                                warningf(msg);

                                // TODO: Tasks pending completion -@zhangxueping at 2020-10-20T14:32:17+08:00
                                // 
                                // throw new EntityException(msg);
                            }
                        }
                    }
                    else
                    {
                        newArgs.add(subExpr);
                    }
                }
                aggreExpr.getArguments().clear();
                aggreExpr.getArguments().addAll(newArgs);
                select_copy.addSelectItem(aggreExpr,selectItem.getAlias());
            }
            else
            {
                version(HUNT_ENTITY_DEBUG_MORE) {
                    auto o = cast(Object)expr;
                    warningf("Expr: %s, item: %s", typeid(o).name, SQLUtils.toSQLString(selectItem));
                }
                select_copy.addSelectItem(selectItem);
            }
        }

        ///from
        auto fromExpr = select_copy.getFrom();
        string[string] aliasModelMap;

        SQLTableSource  tableSource = cast(SQLTableSource)queryBlock.getFrom();
        SQLJoinTableSource joinTableSource = cast(SQLJoinTableSource)tableSource;
        if(joinTableSource !is null) {
            SQLExprTableSource exprTableSource = cast(SQLExprTableSource)joinTableSource.getLeft();
            if(exprTableSource !is null) {
                SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)exprTableSource.getExpr(); 
                string tableAlias = exprTableSource.getAlias();
                
                if(!tableAlias.empty()) {
                    aliasModelMap[tableAlias] = identifierExpr.getName();
                }
            }

            exprTableSource = cast(SQLExprTableSource)joinTableSource.getRight();
            if(exprTableSource !is null) {
                string tableAlias = exprTableSource.getAlias();
                string realName;
                
                SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)exprTableSource.getExpr(); 
                if(identifierExpr !is null) {
                    realName = identifierExpr.getName();
                } 

                SQLPropertyExpr propertyExpr = cast(SQLPropertyExpr)exprTableSource.getExpr(); 
                if(propertyExpr !is null) {
                    realName = propertyExpr.getName();
                } 
                
                if(realName.empty()) {
                    warningf("The actual type: %s", typeid(cast(Object)identifierExpr));
                } else if(!tableAlias.empty()) {
                    aliasModelMap[tableAlias] = realName;
                }
            }
        } else {
            SQLExprTableSource exprTableSource = cast(SQLExprTableSource)tableSource;
            if(exprTableSource !is null) {
                SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)exprTableSource.getExpr(); 
                string tableAlias = tableSource.getAlias();
                
                if(!tableAlias.empty()) {
                    aliasModelMap[tableAlias] = identifierExpr.getName();
                }
            } else {
                warningf("Can't handle table source: %s", typeid(cast(Object)tableSource));
            }
        }

        version(HUNT_ENTITY_DEBUG) {
            warning(aliasModelMap);
        }

        parseFromTable(fromExpr);
               

        ///where 
        auto whereCond = select_copy.getWhere();
        if (whereCond !is null) {
            EqlSubstitutionContext context = new EqlSubstitutionContext();
            context.modelTableMap = _clsNameToTbName;
            context.aliasModelMap = aliasModelMap;
            context.tableFields = _tableFields;
            // context.eqlObjs = _eqlObj;

            // substituteInExpress(whereCond, context);

            // FIXME: Needing refactor or cleanup -@zhangxueping at 2020-09-21T14:59:49+08:00
            // Remove this block below.
            
            string where = SQLUtils.toSQLString(whereCond);
            version (HUNT_ENTITY_DEBUG) warning(where);
            where = convertAttrExpr(where);
            version (HUNT_ENTITY_DEBUG) trace(where);
            SQLExpr newExpr = SQLUtils.toSQLExpr(where);
            substituteInExpress(newExpr, context);
            select_copy.setWhere(newExpr);
        }

        ///order by
        auto orderBy = select_copy.getOrderBy();
        if (orderBy !is null)
        {
            version (HUNT_ENTITY_DEBUG) infof("Parsing the orderBy clause.");
            foreach (item; orderBy.getItems)
            {
                auto exprStr = SQLUtils.toSQLString(item.getExpr(), _dbtype);
                // version (HUNT_ENTITY_DEBUG_MORE)
                //     logDebug("order item : %s".format(exprStr));
                item.replace(item.getExpr(), SQLUtils.toSQLExpr(convertAttrExpr(exprStr), _dbtype));
            }
        }
        // else
        // {
        //     version (HUNT_ENTITY_DEBUG_MORE)
        //         logDebug("order by item is null");
        // }

        /// group by 
        auto groupBy = select_copy.getGroupBy();
        if (groupBy !is null)
        {
            version (HUNT_ENTITY_DEBUG) infof("Parsing the groupBy clause.");
            groupBy.getItems().clear();
            foreach (item; queryBlock.getGroupBy().getItems())
            {
                // logDebug("group item : %s".format(SQLUtils.toSQLString(item)));
                groupBy.addItem(SQLUtils.toSQLExpr(convertAttrExpr(SQLUtils.toSQLString(item))));
            }
            auto having = groupBy.getHaving();
            if (having !is null)
            {
                groupBy.setHaving(SQLUtils.toSQLExpr(
                        convertAttrExpr(SQLUtils.toSQLString(having))));
            }
            select_copy.setGroupBy(groupBy);
        }

        version(HUNT_ENTITY_DEBUG) info("The parsing done. Now, converting it to native SQL...");
        _parsedEql = SQLUtils.toSQLString(select_copy, _dbtype);
        version(HUNT_ENTITY_DEBUG) warning(_parsedEql);

    }

    private void doUpdateParse()
    {
        SQLUpdateStatement updateBlock = cast(SQLUpdateStatement)(_stmtList.get(0));
        /// update item
        foreach (SQLUpdateSetItem updateItem; updateBlock.getItems())
        {
            version(HUNT_ENTITY_DEBUG)
            {
                tracef("Update item (name: %s, value: %s)", SQLUtils.toSQLString(updateItem.getColumn()),
                        SQLUtils.toSQLString(updateItem.getValue));
            }
            SQLExpr expr = updateItem.getColumn();

            if (cast(SQLIdentifierExpr) expr !is null) {
                warning("Do nothing");
            }

            if (cast(SQLPropertyExpr) expr !is null)
            {
                EqlObject eqlObj = _eqlObj.get((cast(SQLPropertyExpr) expr).getOwnernName(), null);
                string currentFieldName = (cast(SQLPropertyExpr) expr).getName();
                if (eqlObj !is null)
                {
                    bool isHandled = false;
                    EntityField fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (string classMember, EntityFieldInfo fieldInfo; fields) {
                            if(fieldInfo.isAggregateType()) {
                                // ignore all the aggregative members;
                                version(HUNT_DEBUG) {
                                    infof("Aggregative member ignored: %s", classMember);
                                }

                                continue;
                            }
                            string columnName = fieldInfo.getColumnName();

                            version(HUNT_ENTITY_DEBUG_MORE) {
                                tracef("classMember: %s, columnName: %s, currentField: %s", 
                                    classMember, columnName, currentFieldName);
                            }

                            isHandled = classMember == currentFieldName || columnName == currentFieldName;
                            if (isHandled) {
                                if (_dbtype == DBType.POSTGRESQL.name) {
                                    // PostgreSQL
                                    // https://www.postgresql.org/docs/9.1/sql-update.html
                                    updateItem.setColumn(new SQLIdentifierExpr(columnName));
                                    // updateItem.setColumn(new SQLPropertyExpr(eqlObj.tableName(),
                                    //         fieldInfo.getColumnName()));
                                } else {
                                    updateItem.setColumn(new SQLPropertyExpr(eqlObj.tableName(), columnName));
                                }
                                
                                break;
                            }
                        }
                    }

                    if(!isHandled) {
                        string msg = format("Found a undefined memeber [%s] in class [%s]", 
                            currentFieldName, eqlObj.className());
                        warningf(msg);

                        // TODO: Tasks pending completion -@zhangxueping at 2020-10-20T14:32:17+08:00
                        // 
                        // throw new EntityException(msg);
                    }
                }
                else
                {
                    eql_throw("Statement",
                        " undefined sql object  '%s' in '%s': ".format((cast(SQLPropertyExpr) expr).getOwnernName(),
                        SQLUtils.toSQLString(expr)));
                }
            }

            auto valueExpr = updateItem.getValue();
            if (cast(SQLPropertyExpr) valueExpr !is null)
            {
                auto eqlObj = _eqlObj.get((cast(SQLPropertyExpr) valueExpr).getOwnernName(), null);
                string currentFieldName = (cast(SQLPropertyExpr) valueExpr).getName();
                if (eqlObj !is null)
                {
                    bool isHandled = false;
                    EntityField fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (string classMember, EntityFieldInfo fieldInfo; fields)
                        {
                            string columnName = fieldInfo.getColumnName();

                            version(HUNT_ENTITY_DEBUG_MORE) {
                                tracef("classMember: %s, columnName: %s, currentField: %s", 
                                    classMember, columnName, currentFieldName);
                            }

                            isHandled = classMember == currentFieldName || columnName == currentFieldName;
                            if (isHandled)
                            {
                                updateItem.setValue(new SQLPropertyExpr(eqlObj.tableName(),
                                        columnName));
                                break;
                            }
                            // tracef("sql replace : (%s ,%s) ", classMember, fieldInfo.getColumnName());
                        }
                    }
                    
                    if(!isHandled) {
                        string msg = format("Found a undefined memeber [%s] in class [%s]", 
                            currentFieldName, eqlObj.className());
                        warningf(msg);

                        // TODO: Tasks pending completion -@zhangxueping at 2020-10-20T14:32:17+08:00
                        // 
                        // throw new EntityException(msg);
                    }
                }
            }
        }

        ///from
        auto fromExpr = updateBlock.getTableSource();
        // logDebug("update From : %s".format(SQLUtils.toSQLString(fromExpr)));
        parseFromTable(fromExpr);

        ///where 
        SQLExpr whereCond = updateBlock.getWhere();
        if (whereCond !is null)
        {
            string where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            updateBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        version(HUNT_ENTITY_DEBUG) info("The parsing done. Now, converting it to native SQL...");
        _parsedEql = SQLUtils.toSQLString(updateBlock, _dbtype);
        version (HUNT_ENTITY_DEBUG) {
            warning(_parsedEql);
        }
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
        if (whereCond !is null)
        {
            auto where = SQLUtils.toSQLString(whereCond);
            where = convertAttrExpr(where);
            delBlock.setWhere(SQLUtils.toSQLExpr(where));
        }

        _parsedEql = SQLUtils.toSQLString(delBlock, _dbtype);
    }

    private void doInsertParse()
    {
        SQLInsertStatement insertBlock = cast(SQLInsertStatement)(_stmtList.get(0));

        List!SQLExpr newColumns = new ArrayList!SQLExpr();

        /// insert item
        foreach (expr; insertBlock.getColumns())
        {
            version(HUNT_ENTITY_DEBUG_MORE)
                trace("insert item :", SQLUtils.toSQLString(expr));
            if (cast(SQLIdentifierExpr) expr !is null)
            {
                newColumns.add(expr);
            }
            if (cast(SQLPropertyExpr) expr !is null)
            {
                SQLPropertyExpr pExpr = cast(SQLPropertyExpr) expr;
                auto eqlObj = _eqlObj.get(pExpr.getOwnernName(), null);
                string currentFieldName = (cast(SQLPropertyExpr) expr).getName();
                if (eqlObj !is null)
                {
                    bool isHandled = false;
                    auto fields = _tableFields.get(eqlObj.className(), null);
                    if (fields !is null)
                    {
                        foreach (classMember, fieldInfo; fields)
                        {
                            string columnName = fieldInfo.getColumnName();

                            version(HUNT_ENTITY_DEBUG_MORE) {
                                tracef("classMember: %s, columnName: %s, currentField: %s", 
                                    classMember, columnName, currentFieldName);
                            }

                            isHandled = classMember == currentFieldName || columnName == currentFieldName;

                            if (isHandled)
                            {
                                newColumns.add(new SQLIdentifierExpr(fieldInfo.getColumnName()));
                                break;
                            }
                        }
                        
                        if(!isHandled) {
                            string msg = format("Found a undefined memeber [%s] in class [%s]", 
                                currentFieldName, eqlObj.className());
                            warningf(msg);

                            // TODO: Tasks pending completion -@zhangxueping at 2020-10-20T14:32:17+08:00
                            // 
                            // throw new EntityException(msg);
                        }
                    }
                }
                else
                {
                    eql_throw("Statement",
                    " undefined sql object  '%s' in '%s': ".format(pExpr.getOwnernName(),SQLUtils.toSQLString(pExpr)));
                }
            }
            insertBlock.getColumns().clear();
            insertBlock.getColumns().addAll(newColumns);

            // auto valueExpr = updateItem.getValue();
            // if (cast(SQLPropertyExpr) valueExpr !is null)
            // {
            //     auto eqlObj = _eqlObj.get((cast(SQLPropertyExpr) valueExpr).getOwnernName(), null);
            //     auto clsFieldName = (cast(SQLPropertyExpr) valueExpr).getName();
            //     if (eqlObj !is null)
            //     {
            //         auto fields = _tableFields.get(eqlObj.className(), null);
            //         if (fields !is null)
            //         {
            //             foreach (classMember, fieldInfo; fields)
            //             {
            //                 if (classMember == clsFieldName)
            //                 {
            //                     updateItem.setValue(new SQLPropertyExpr(eqlObj.tableName(),
            //                             fieldInfo.getColumnName()));
            //                     break;
            //                 }
            //                 // logDebug("sql replace : (%s ,%s) ".format(k ~ "." ~ classMember,k ~ "." ~ fieldInfo.getColumnName()));
            //             }
            //         }
            //     }
            // }
        }

        ///from
        SQLExprTableSource fromExpr = insertBlock.getTableSource();
        // version (HUNT_DEBUG)
        //     logDebug("Insert into: %s".format(SQLUtils.toSQLString(fromExpr)));
        parseFromTable(fromExpr);

        _parsedEql = SQLUtils.toSQLString(insertBlock, _dbtype);

        if(_dbtype == DBType.POSTGRESQL) {
            string autoIncrementKey = _entityInfo.autoIncrementKey;
            _parsedEql = _parsedEql.stripRight(";");
            if(!autoIncrementKey.empty()) {
                _parsedEql ~= " RETURNING " ~ autoIncrementKey ~ ";";
            }
        }
    }

    /// a.id  --- > Class.id , a is instance of Class
    private string convertExprAlias(SQLPropertyExpr expr)
    {
        string originStr = SQLUtils.toSQLString(expr);
        auto objName = expr.getOwnernName();
        auto subPropertyName = expr.getName();
        auto aliasMap = _aliasVistor.getAliasMap();
        string clsName;
        foreach (obj, v; aliasMap)
        {
            if (obj == objName)
            {
                auto exprTab = (cast(SQLExprTableSource) v).getExpr();
                if (cast(SQLIdentifierExpr) exprTab !is null)
                {
                    expr.setOwner(exprTab);
                }
                else if (cast(SQLPropertyExpr) exprTab !is null)
                {
                    expr.setOwner(SQLUtils.toSQLExpr(
                            convertExprAlias(cast(SQLPropertyExpr) exprTab)));
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
        auto conds = matchAll(attrExpr, regex("([^\\(\\s]+)\\.([^\\s]+)"));
        bool[string] handerFlag;
        foreach (cond; conds)
        {
            string newCond = cond.captures[0];
            if (newCond in handerFlag)
                continue;
            else
                handerFlag[newCond] = true;
            
            string owner = cond.captures[1];
            auto eqlObj = _eqlObj.get(owner, null);
            if (eqlObj !is null)
            {
                newCond = newCond.replace(owner ~ ".", eqlObj.tableName() ~ ".");
                auto fields = _tableFields.get(eqlObj.className(), null);
                if (fields !is null)
                {
                    foreach (classMember, fieldInfo; fields)
                    {
                        if (classMember == cond.captures[2])
                            newCond = newCond.replace("." ~ cond.captures[2],
                                    "." ~ fieldInfo.getColumnName());

                    }
                }
            }
            res = res.replace(cond.captures[0], newCond);
        }
        return res;
    }

    /// remove alias & a.xx -- > Table
    private void parseFromTable(SQLTableSource fromExpr)
    {
        version (HUNT_ENTITY_DEBUG) infof("Parsing the FROM clause. The type is: %s", typeid(cast(Object)fromExpr));
        if (fromExpr is null)
        {
            eql_throw("Table", "no found table");
        }
        // logDebug(" From table : %s".format(SQLUtils.toSQLString(fromExpr)));
        if (cast(SQLJoinTableSource) fromExpr !is null)
        {
            auto joinExpr = cast(SQLJoinTableSource) fromExpr;
            auto rightExpr = cast(SQLExprTableSource)(joinExpr.getRight());

            auto defaultJoinCond = joinExpr.getCondition();
            if (defaultJoinCond is null)
            {
                // logDebug("join table no default condition");
            }
            else
            {
                auto convertAttrStr = convertAttrExpr(SQLUtils.toSQLString(defaultJoinCond));
                // logDebug(" join Cond : %s , convert : %s ".format(SQLUtils.toSQLString(defaultJoinCond),convertAttrStr));
                joinExpr.setCondition(SQLUtils.toSQLExpr(convertAttrStr));
            }

            if (cast(SQLJoinTableSource)(joinExpr.getLeft()) !is null)
            {
                auto subExpr = cast(SQLJoinTableSource)(joinExpr.getLeft());
                parseFromTable(subExpr);
            }
            else if (cast(SQLExprTableSource)(joinExpr.getLeft()) !is null)
            {
                auto leftExpr = cast(SQLExprTableSource)(joinExpr.getLeft());

                if (cast(SQLPropertyExpr)(leftExpr.getExpr()) !is null)
                {
                    string convertStr = convertExprAlias(cast(SQLPropertyExpr)(leftExpr.getExpr()));
                    string clsName = _objType.get(convertStr, null);
                    if (clsName !is null)
                    {
                        auto tableName = _clsNameToTbName.get(clsName, null);
                        if (tableName !is null)
                        {
                            leftExpr.setExpr(tableName);
                        }
                    }

                    Object joinCond = _joinConds.get(convertStr, null);
                    version(HUNT_ENTITY_DEBUG) {
                        logDebugf("add cond (left): ( %s , %s ), convertStr: %s", clsName, joinCond, convertStr);
                    }
                    
                    if (joinCond !is null)
                    {
                        joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond.toString()));
                    }
                }
                else if (cast(SQLIdentifierExpr)(leftExpr.getExpr()) !is null)
                {
                    auto clsName = (cast(SQLIdentifierExpr)(leftExpr.getExpr())).getName();
                    auto tableName = _clsNameToTbName.get(clsName, null);
                    if (tableName !is null)
                    {
                        leftExpr.setExpr(tableName);
                    }
                }
                leftExpr.setAlias("");
            }

            if (rightExpr is null)
                return;
            if (cast(SQLPropertyExpr)(rightExpr.getExpr()) !is null)
            {
                auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(rightExpr.getExpr()));
                auto clsName = _objType.get(convertStr, null);
                if (clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName, null);
                    if (tableName !is null)
                    {
                        rightExpr.setExpr(tableName);
                    }
                }
                auto joinCond = _joinConds.get(convertStr, null);
                warning(_joinConds);
                version(HUNT_ENTITY_DEBUG) {
                    logDebugf("add cond (right) : ( %s , %s ), convertStr: %s", clsName, joinCond, convertStr);
                }

                if (joinCond !is null)
                {
                    joinExpr.setCondition(SQLUtils.toSQLExpr(joinCond.toString()));
                }
            }
            else if (cast(SQLIdentifierExpr)(rightExpr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(rightExpr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName, null);
                if (tableName !is null)
                {
                    rightExpr.setExpr(tableName);
                }
            }

            rightExpr.setAlias("");
        }
        else
        {
            auto expr = cast(SQLExprTableSource)(fromExpr);
            if (expr is null)
                return;
            if (cast(SQLPropertyExpr)(expr.getExpr()) !is null)
            {
                auto convertStr = convertExprAlias(cast(SQLPropertyExpr)(expr.getExpr()));
                auto clsName = _objType.get(convertStr, null);
                if (clsName !is null)
                {
                    auto tableName = _clsNameToTbName.get(clsName, null);
                    if (tableName !is null)
                    {
                        expr.setExpr(tableName);
                    }
                }

            }
            else if (cast(SQLIdentifierExpr)(expr.getExpr()) !is null)
            {
                auto clsName = (cast(SQLIdentifierExpr)(expr.getExpr())).getName();
                auto tableName = _clsNameToTbName.get(clsName, null);
                if (tableName !is null)
                {
                    expr.setExpr(tableName);
                }
            }
            expr.setAlias("");
        }
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
        else static if (is(R == byte[]) || is(R == ubyte[]))
        {
            _params[idx] = new Bytes(cast(byte[]) param);
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
            _params[idx] = param;
        }
        else
        {
            eql_throw("setParameter", "IllegalArgument not support : " ~ R.stringof);
        }
    }

    public void setParameter(R)(string key, R param)
    {
        static if (is(R == int) || is(R == uint))
        {
            _parameters[key] = new Integer(param);
        }
        else static if (is(R == char))
        {
            _parameters[key] = new String(cast(string)[param]);
        }
        else static if (is(R == string))
        {
            _parameters[key] = new String(param);
        }
        else static if (is(R == byte[]) || is(R == ubyte[]))
        {
            _parameters[key] = new Bytes(cast(byte[]) param);
        }
        // else static if (is(R == string) || is(R == char) || is(R == byte[]))
        // {
        //     _parameters[key] = new String(param);
        // }
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
            eql_throw("setParameter", "IllegalArgument not support : " ~ R.stringof);
        }
    }

    public void putClsTbName(string clsName, string tableName)
    {
        _clsNameToTbName[clsName] = tableName;
    }

    public void putFields(string table, EntityField ef)
    {
        version(HUNT_ENTITY_DEBUG) {
            infof("table: %s", table);
            foreach (string classMember, EntityFieldInfo fieldInfo; ef) {
                    tracef("classMember: %s,  isAggregateType: %s, fullColumn: [%s]", 
                        classMember, fieldInfo.isAggregateType(), fieldInfo.getFullColumn());
                }  
        }      
        _tableFields[table] = ef;
    }

    public void putJoinCond(Object[string] conds)
    {
        foreach (k, v; conds)
        {
            _joinConds[k] = v;
        }
    }

    public string getTableName(string clsName)
    {
        return _clsNameToTbName.get(clsName, null);
    }

    public string getNativeSql()
    {
        if(!_nativeSql.empty())
            return _nativeSql;

        string sql = _parsedEql;

        version (HUNT_ENTITY_DEBUG_MORE)
            logDebug("EQL params : ", _parameters);

        foreach (k, v; _parameters)
        {
            auto re = regex(r":" ~ k ~ r"([^\w]*)", "g");
            if (cast(String) v !is null || (cast(Nullable!string) v !is null))
            {
                version (HUNT_ENTITY_DEBUG_MORE)
                    logInfo("-----: ", v.toString);
                if (_dbtype == DBType.POSTGRESQL.name)
                    sql = sql.replaceAll(re, quoteSqlString(v.toString(), "'") ~ "$1");
                else
                    sql = sql.replaceAll(re, quoteSqlString(v.toString()) ~ "$1");
            }
            else
            {
                sql = sql.replaceAll(re, v.toString() ~ "$1");
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
            sql = SQLUtils.format(sql, _dbtype, params, _formatOption);
            // sql = SQLUtils.format(sql, _dbtype, params);
        } else {
            sql = SQLUtils.format(sql, _dbtype, _formatOption);
            // sql = SQLUtils.format(sql, _dbtype);
        }

        // FIXME: Needing refactor or cleanup -@zhangxueping at 2019-10-09T14:41:55+08:00
        // why?
        // if (_dbtype == DBType.POSTGRESQL.name && _params.length == 0) {
        //     sql = SQLUtils.format(sql, _dbtype, _formatOption);
        //     warning(sql);
        // }

        version(HUNT_ENTITY_DEBUG) infof("result sql : %s", sql);
        _nativeSql = sql;
        return sql;
    }


    // SQLInSubQueryExpr
    static void substitute(SQLInSubQueryExpr subQueryExpr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling a SQLInSubQueryExpr");

        // in express
        SQLPropertyExpr expr =  cast(SQLPropertyExpr)subQueryExpr.getExpr();
        string ownerName = expr.getOwnernName();
        auto itemPtr = ownerName in context.aliasModelMap;
        if(itemPtr !is null) {
            ownerName = *itemPtr;
            ownerName = context.modelTableMap.get(ownerName, ownerName);
            expr.setOwner(ownerName);
        }

        // version (HUNT_ENTITY_DEBUG) warningf("ownerName: %s", ownerName);

        // select clause
        substitute(subQueryExpr.getSubQuery(), context);

    }

    // SQLIdentifierExpr
    static void substitute(SQLIdentifierExpr expr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling an SQLIdentifierExpr");
        string className = expr.getName();
        // version (HUNT_ENTITY_DEBUG) tracef("className: %s",  className);

        auto itemPtr = className in context.modelTableMap;
        if(itemPtr is null) {
            version (HUNT_ENTITY_DEBUG) warningf("No mapped model name found for class: %s", className);
        } else {
            expr.setName(*itemPtr);
        }
    }

    // SQLPropertyExpr
    static void substitute(SQLPropertyExpr expr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling an SQLPropertyExpr");

        string ownerName = expr.getOwnernName();
        string fieldName = expr.getName();

        if(ownerName.empty()) {
            warningf("No owner found before [%s]", fieldName);
            return;
        }

        version (HUNT_ENTITY_DEBUG) trace(context.tableFields.keys);
        
        // owner
        string modelName = context.getModelByAlias(ownerName, ownerName);
        string tableName = context.getTableByModel(modelName, modelName);

        if(tableName != ownerName) {
            expr.setOwner(tableName);
        }

        version (HUNT_ENTITY_DEBUG) {
            tracef("ownerName, alias: %s, model: %s, table: %s", ownerName, modelName, tableName);
        }

        // name
        EntityFieldInfo[string] fields = context.tableFields.get(modelName, null);
        foreach (string member, EntityFieldInfo fieldInfo; fields) {
            if(member == fieldName) {
                string columnName = fieldInfo.getColumnName();
                version (HUNT_ENTITY_DEBUG_MORE) {
                    tracef("The field's name is substituted from [%s] to [%s]", fieldName, columnName);
                }
                expr.setName(columnName);
                break;
            }
        }

        // TODO: Tasks pending completion -@zhangxueping at 2020-09-21T11:41:18+08:00
        // a => *
    }


    // SQLBinaryOpExpr
    static void substitute(SQLBinaryOpExpr expr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling an SQLBinaryOpExpr");

        // Left
        SQLExpr leftExpr = expr.getLeft();
        substituteInExpress(leftExpr, context);

        // Right
        SQLExpr rightExpr = expr.getRight();
        substituteInExpress(rightExpr, context);
    }
    
    static void substitute(SQLNumericLiteralExpr expr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling an SQLNumericLiteralExpr");
        // do nothing
    }
    
    static void substitute(SQLTextLiteralExpr expr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling an SQLTextLiteralExpr");
        // do nothing
    }
    
    static void substitute(SQLInListExpr expr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) tracef("Handling an SQLInListExpr");
        SQLExpr sqlExpr = expr.getExpr();

        substituteInExpress(sqlExpr, context);

        //
        List!SQLExpr targets = expr.getTargetList();
        foreach(SQLExpr se; targets) {
            substituteInExpress(se, context);
        }
    }

    static void substituteInExpress(SQLExpr sqlExpr, EqlSubstitutionContext context) {
        version (HUNT_ENTITY_DEBUG) infof("Handling an express: %s", typeid(cast(Object)sqlExpr));

        SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)sqlExpr;
        if(identifierExpr !is null) {
            substitute(identifierExpr, context);
            return;
        }

        SQLPropertyExpr propertyExpr = cast(SQLPropertyExpr)sqlExpr;
        if(propertyExpr !is null) {
            substitute(propertyExpr, context);
            return;
        }

        SQLInSubQueryExpr subQueryExpr = cast(SQLInSubQueryExpr)sqlExpr;
        if(subQueryExpr !is null) {
            substitute(subQueryExpr, context);
            return;
        }

        SQLBinaryOpExpr opExpr = cast(SQLBinaryOpExpr)sqlExpr;
        if(opExpr !is null) {
            substitute(opExpr, context);
            return;
        }

        SQLNumericLiteralExpr numberExpr = cast(SQLNumericLiteralExpr)sqlExpr;
        if(numberExpr !is null) {
            substitute(numberExpr, context);
            return;
        }

        SQLTextLiteralExpr textExpr = cast(SQLTextLiteralExpr)sqlExpr;
        if(textExpr !is null) {
            substitute(textExpr, context);
            return;
        }
        
        SQLInListExpr inListExpr = cast(SQLInListExpr)sqlExpr;
        if(inListExpr !is null) {
            substitute(inListExpr, context);
            return;
        }

        warningf("A express can't be handled: %s", typeid(cast(Object)sqlExpr));
    }

    static void substitute(SQLSelect subSelect, EqlSubstitutionContext context) {
        SQLSelectQueryBlock queryBlock = cast(SQLSelectQueryBlock)subSelect.getQuery();

        // The FROM clause 
        SQLExprTableSource  fromExpr = cast(SQLExprTableSource)queryBlock.getFrom();
        string tableAlias = fromExpr.getAlias();
        if(!tableAlias.empty()) {
            fromExpr.setAlias("");
        
            SQLIdentifierExpr identifierExpr = cast(SQLIdentifierExpr)fromExpr.getExpr();
            if(identifierExpr !is null) {
                version (HUNT_ENTITY_DEBUG) tracef("Removing the alias: %s", tableAlias);
                context.aliasModelMap[tableAlias] = identifierExpr.getName();
            }
        }

        SQLExpr sqlExpr = fromExpr.getExpr();
        substituteInExpress(sqlExpr, context);

        // The selected fields
        foreach (SQLSelectItem selectItem; queryBlock.getSelectList()) {
            SQLExpr expr = selectItem.getExpr();
            substituteInExpress(expr, context);
        }

        // where
        SQLExpr whereExpr = queryBlock.getWhere();
        if(whereExpr !is null) {
            substituteInExpress(whereExpr, context);
        }
    }
}
