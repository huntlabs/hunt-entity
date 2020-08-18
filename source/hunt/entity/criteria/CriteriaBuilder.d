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
 
module hunt.entity.criteria.CriteriaBuilder;

import hunt.entity;
import hunt.entity.dialect;
import hunt.Exceptions;
import hunt.logging;

import std.conv;
import std.format;
import std.traits;
import std.variant;

class CriteriaBuilder
{

    private EntityManagerFactory _factory;
    private EntityManager _manager;

    this(EntityManagerFactory factory) {
        _factory = factory;
    }

    CriteriaBuilder setManager(EntityManager manager) {
        _manager = manager;
        return this;
    }

    EntityManager getManager() {return _manager;}

    QueryBuilder createQueryBuilder() {
        return _factory.createQueryBuilder();
    }

    Dialect getDialect() {
        return _factory.getDialect();
    } 

    // Database getDatabase() {
    //     return _factory.getDatabase();
    // }

    CriteriaQuery!(T,F) createQuery(T : Object,F : Object = T)() {
        return new CriteriaQuery!(T,F)(this);
    }

    CriteriaDelete!(T,F) createCriteriaDelete(T : Object,F : Object = T)() {
        return new CriteriaDelete!(T,F)(this);
    }

    CriteriaUpdate!(T,F) createCriteriaUpdate(T : Object,F : Object = T)() {
        return new CriteriaUpdate!(T,F)(this);
    }

    Order asc(EntityFieldInfo info) {
        return new Order(info.getFullColumn(), OrderBy.ASC);
    }

    Order desc(EntityFieldInfo info) {
        return new Order(info.getFullColumn(), OrderBy.DESC);
    }

    //P should be Predicate
    Predicate and(P...)(P predicates) {
        return new Predicate().andValue(predicates);
    }

    //P should be Predicate
    Predicate or(P...)(P predicates) {
        return new Predicate().orValue(predicates);
    }

    EntityExpression max(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("MAX");
    }

    EntityExpression min(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("MIN");
    }

    EntityExpression avg(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("AVG");
    }

    EntityExpression sum(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("SUM");
    }

    EntityExpression count(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("COUNT");
    }

    EntityExpression count(T)(Root!T root) {
        return new EntityExpression(root.getPrimaryField().getColumnName(), root.getPrimaryField().getTableName()).setColumnSpecifier("COUNT");
    }

    EntityExpression countDistinct(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setDistinct(true).setColumnSpecifier("COUNT");
    }

    EntityExpression countDistinct(T)(Root!T root) {
        return new EntityExpression(root.getPrimaryField().getColumnName(), root.getPrimaryField().getTableName()).setDistinct(true).setColumnSpecifier("COUNT");
    }

    Predicate equal(T)(EntityFieldInfo info, T t, bool check = true) {
        static if (isBuiltinType!T) {
            if (check)
                assertType!(T)(info);
                return new Predicate().addValue(info.getFullColumn(), "=", quoteSqlfNeed(t));
        }
        else {
            Predicate p;
            if (info.getJoinColumn() != "") {
                auto entityInfo = new EntityInfo!(T,T)(_manager, t);
                p = new Predicate().addValue(info.getJoinColumn(), "=", quoteSqlfNeed(entityInfo.getPrimaryValue()));
            }
            else {
                throw new EntityException("cannot compare field %s with type %".format(info.getFieldName(), typeid(T).stringof));
            }
            return p;
        }
    }


    /// for get lazy data
    Predicate lazyEqual(T)(EntityFieldInfo info, T t, bool check = true) {
        static if (isBuiltinType!T) {
            if (check)
                assertType!(T)(info);
                return new Predicate().addValue(info.getFullColumn(), "=", t);
        }
        else {
            Predicate p;
            if (info.getJoinColumn() != "") {
                auto entityInfo = new EntityInfo!(T,T)(_manager, t);
                p = new Predicate().addValue(info.getJoinColumn(), "=", quoteSqlfNeed(entityInfo.getPrimaryValue()));
            }
            else {
                throw new EntityException("cannot compare field %s with type %".format(info.getFieldName(), typeid(T).stringof));
            }
            return p;
        }
    }

    /// for get lazy data
    Predicate lazyManyToManyEqual(T)(EntityFieldInfo info, T t, bool check = true) {
        auto condTable = info.getJoinTable();
        auto condColumn = info.getJoinColumn();
        if(info.isMainMapped())
            condColumn = info.getInverseJoinColumn();
        static if (isBuiltinType!T) {
            if (check)
                assertType!(T)(info);
                return new Predicate().addValue(condTable~"."~condColumn, "=", t);
        }
        else {
            Predicate p;
            if (info.getJoinColumn() != "") {
                auto entityInfo = new EntityInfo!(T,T)(_manager, t);
                p = new Predicate().addValue(condTable~"."~condColumn, "=", quoteSqlfNeed(entityInfo.getPrimaryValue()));
            }
            else {
                throw new EntityException("cannot compare field %s with type %".format(info.getFieldName(), typeid(T).stringof));
            }
            return p;
        }
    }

    Predicate equal(EntityFieldInfo info) {
        return new Predicate().addValue(info.getFullColumn(), "=", info.getColumnFieldData().toString());
    }

    Predicate notEqual(T)(EntityFieldInfo info, T t){

        static if (isBuiltinType!T) {
            if (check)
                assertType!(T)(info);
            return new Predicate().addValue(info.getFullColumn(), "<>", quoteSqlfNeed(t));
        }
        else {
            Predicate p;
            if (info.getJoinColumn() != "") {
                auto entityInfo = new EntityInfo!(T,T)(_manager, t);
                p = new Predicate().addValue(info.getJoinColumn(), "<>", quoteSqlfNeed(entityInfo.getPrimaryValue()));
            }
            else {
                throw new EntityException("cannot compare field %s with type %".format(info.getFieldName(), typeid(T).stringof));
            }
            return p;
        }
    }

    Predicate notEqual(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), "<>", info.getColumnFieldData().toString());
    }

    Predicate gt(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), ">", quoteSqlfNeed(t));
    }

    Predicate gt(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), ">", info.getColumnFieldData().toString());
    }

    Predicate ge(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), ">=", quoteSqlfNeed(t));
    }

    Predicate ge(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), ">=", info.getColumnFieldData().toString());
    }

    Predicate lt(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), "<", quoteSqlfNeed(t));
    }

    Predicate lt(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), "<", info.getColumnFieldData().toString());
    }

    Predicate le(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), "<=", quoteSqlfNeed(t));
    }

    Predicate le(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), "<=", info.getColumnFieldData().toString());
    }

    Predicate like(EntityFieldInfo info, string pattern) {
        return new Predicate().addValue(info.getFullColumn(), "like", quoteSqlfNeed(pattern));
    }

    Predicate notLike(EntityFieldInfo info, string pattern) {
        return new Predicate().addValue(info.getFullColumn(), "not like", quoteSqlfNeed(pattern));
    }

    Predicate between(T)(EntityFieldInfo info, T t1, T t2) {
        assertType!(T)(info);
        return new Predicate().betweenValue(info.getFullColumn(), quoteSqlfNeed(t1), quoteSqlfNeed(t2));
    }

    Predicate In(T...)(EntityFieldInfo info, T args) {
        foreach(k,v; args) {
            if (k == 0) {
                assertType!(typeof(v))(info);
            }
        }
        return new Predicate().In(info.getFullColumn(), args);
    }

    void assertType(T)(EntityFieldInfo info) {
        if (info.getColumnFieldData().hasValue()) {
            static if (is(T == string)) {
                if (info.getColumnFieldData().type != typeid(string)) {
                    throw new EntityException("EntityFieldInfo %s type need been string not %s".format(info.getFieldName(), info.getColumnFieldData().type));
                }
            }else {
                if (info.getColumnFieldData().type == typeid(string)) {
                    throw new EntityException("EntityFieldInfo %s type need been number not string".format(info.getFieldName()));
                }
            }
        }
        else {
            throw new EntityException("EntityFieldInfo %s is object can not be Predicate".format(info.getFieldName()));
        }   
    }

    private string quoteSqlfNeed(T)(T t)
    {
        static if(is(T == string)) {
            // return _manager.getDatabase.escapeWithQuotes(t);
            implementationMissing(false);
            return t;
        } else {
            return t.to!string;
        }
    }
}
