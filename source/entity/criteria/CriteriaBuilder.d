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
 
module entity.criteria.CriteriaBuilder;

import entity;

public class CriteriaBuilder
{

    private EntityManagerFactory _factory;
    private EntityManager _manager;

    this(EntityManagerFactory factory) {
        _factory = factory;
    }

    public CriteriaBuilder setManager(EntityManager manager) {
        _manager = manager;
        return this;
    }

    public EntityManager getManager() {return _manager;}

    public SqlBuilder createSqlBuilder() {
        return _factory.createSqlBuilder();
    }

    public Dialect getDialect() {
        return _factory.getDialect();
    } 

    public Database getDatabase() {
        return _factory.getDatabase();
    }

    public CriteriaQuery!T createQuery(T)() {
        return new CriteriaQuery!(T)(this);
    }

    public CriteriaDelete!T createCriteriaDelete(T)() {
        return new CriteriaDelete!(T)(this);
    }

    public CriteriaUpdate!T createCriteriaUpdate(T)() {
        return new CriteriaUpdate!(T)(this);
    }

    public Order asc(EntityFieldInfo info) {
        return new Order(info.getFullColumn(), OrderBy.ASC);
    }

    public Order desc(EntityFieldInfo info) {
        return new Order(info.getFullColumn(), OrderBy.DESC);
    }

    //P should be Predicate
    public Predicate and(P...)(P predicates) {
        return new Predicate().andValue(predicates);
    }

    //P should be Predicate
    public Predicate or(P...)(P predicates) {
        return new Predicate().orValue(predicates);
    }

    public EntityExpression max(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("MAX");
    }

    public EntityExpression min(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("MIN");
    }

    public EntityExpression avg(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("AVG");
    }

    public EntityExpression sum(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("SUM");
    }

    public EntityExpression count(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setColumnSpecifier("COUNT");
    }

    public EntityExpression count(T)(Root!T root) {
        return new EntityExpression(root.getPrimaryField().getColumnName(), root.getPrimaryField().getTableName()).setColumnSpecifier("COUNT");
    }

    public EntityExpression countDistinct(EntityFieldInfo info) {
        return new EntityExpression(info.getColumnName(), info.getTableName()).setDistinct(true).setColumnSpecifier("COUNT");
    }

    public EntityExpression countDistinct(T)(Root!T root) {
        return new EntityExpression(root.getPrimaryField().getColumnName(), root.getPrimaryField().getTableName()).setDistinct(true).setColumnSpecifier("COUNT");
    }

    public Predicate equal(T)(EntityFieldInfo info, T t) {
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), "=", _factory.getDialect().toSqlValue(t));
    }

    public Predicate equal(EntityFieldInfo info) {
        return new Predicate().addValue(info.getFullColumn(), "=", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate notEqual(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), "<>", _factory.getDialect().toSqlValue(t));
    }

    public Predicate notEqual(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), "<>", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate gt(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), ">", _factory.getDialect().toSqlValue(t));
    }

    public Predicate gt(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), ">", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate ge(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), ">=", _factory.getDialect().toSqlValue(t));
    }

    public Predicate ge(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), ">=", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate lt(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), "<", _factory.getDialect().toSqlValue(t));
    }

    public Predicate lt(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), "<", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate le(T)(EntityFieldInfo info, T t){
        assertType!(T)(info);
        return new Predicate().addValue(info.getFullColumn(), "<=", _factory.getDialect().toSqlValue(t));
    }

    public Predicate le(EntityFieldInfo info){
        return new Predicate().addValue(info.getFullColumn(), "<=", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate like(EntityFieldInfo info, string pattern) {
        return new Predicate().addValue(info.getFullColumn(), "like", _factory.getDialect().toSqlValue(pattern));
    }

    public Predicate notLike(EntityFieldInfo info, string pattern) {
        return new Predicate().addValue(info.getFullColumn(), "not like", _factory.getDialect().toSqlValue(pattern));
    }

    public Predicate between(T)(EntityFieldInfo info, T t1, T t2) {
        assertType!(T)(info);
        return new Predicate().betweenValue(info.getFullColumn(), _factory.getDialect().toSqlValue(t1), _factory.getDialect().toSqlValue(t2));
    }

    public Predicate In(T...)(EntityFieldInfo info, T args) {
        foreach(k,v; args) {
            if (k == 0) {
                assertType!(typeof(v))(info);
            }
        }
        return new Predicate().In(info.getFullColumn(), args);
    }

    public void assertType(T)(EntityFieldInfo info) {
        if (cast(EntityFieldNormal)info !is null)
            (cast(EntityFieldNormal)info).assertType!T;
        else 
            throw new EntityException("EntityFieldInfo %s is object can not be Predicate".format(info.getFileldName()));
    }
}
