
module entity.criteria.CriteriaBuilder;

import entity;

public class CriteriaBuilder {

    private EntityManagerFactory _factory;

    this(EntityManagerFactory factory) {
        _factory = factory;
    }

    public SqlBuilder createSqlBuilder() {
        return _factory.createSqlBuilder();
    }

    public Dialect getDialect() {
        return _factory.getDialect();
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
        return new Order(info.getColumnName(), OrderBy.Asc);
    }

    public Order desc(EntityFieldInfo info) {
        return new Order(info.getColumnName(), OrderBy.Desc);
    }

    //P should be Predicate
    public Predicate and(P...)(P predicates) {
        return new Predicate().andValue(predicates);
    }
    //P should be Predicate
    public Predicate or(P...)(P predicates) {
        return new Predicate().orValue(predicates);
    }

    public EntityFieldInfo max(EntityFieldInfo info) {
        return new EntityFieldInfo(info.getColumnName()).setColumeSpecifier("MAX");
    }
    public EntityFieldInfo min(EntityFieldInfo info) {
        return new EntityFieldInfo(info.getColumnName()).setColumeSpecifier("MIN");
    }
    public EntityFieldInfo avg(EntityFieldInfo info) {
        return new EntityFieldInfo(info.getColumnName()).setColumeSpecifier("AVG");
    }
    public EntityFieldInfo sum(EntityFieldInfo info) {
        return new EntityFieldInfo(info.getColumnName()).setColumeSpecifier("SUM");
    }
    public EntityFieldInfo count(EntityFieldInfo info) {
        return new EntityFieldInfo(info.getColumnName()).setColumeSpecifier("COUNT");
    }
    public EntityFieldInfo count(T)(Root!T root) {
        return new EntityFieldInfo("*").setColumeSpecifier("COUNT");
    }
    public EntityFieldInfo countDistinct(EntityFieldInfo info) {
        return new EntityFieldInfo("DISTINCT "~info.getColumnName()).setColumeSpecifier("COUNT");
    }
    public EntityFieldInfo countDistinct(T)(Root!T root) {
        return new EntityFieldInfo("DISTINCT *").setColumeSpecifier("COUNT");
    }

    

    public Predicate equal(T)(EntityFieldInfo info, T t) {
        info.assertType!T;
        return new Predicate().addValue(info.getFileldName(), "=", _factory.getDialect().toSqlValue(t));
    }
    public Predicate equal(EntityFieldInfo info) {
        return new Predicate().addValue(info.getFileldName(), "=", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }
    public Predicate notEqual(T)(EntityFieldInfo info, T t){
        info.assertType!T;
        return new Predicate().addValue(info.getFileldName(), "<>", _factory.getDialect().toSqlValue(t));
    }
    public Predicate notEqual(EntityFieldInfo info){
        return new Predicate().addValue(info.getFileldName(), "<>", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate gt(T)(EntityFieldInfo info, T t){
        info.assertType!T;
        return new Predicate().addValue(info.getFileldName(), ">", _factory.getDialect().toSqlValue(t));
    }
    public Predicate gt(EntityFieldInfo info){
        return new Predicate().addValue(info.getFileldName(), ">", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate ge(T)(EntityFieldInfo info, T t){
        info.assertType!T;
        return new Predicate().addValue(info.getFileldName(), ">=", _factory.getDialect().toSqlValue(t));
    }
    public Predicate ge(EntityFieldInfo info){
        return new Predicate().addValue(info.getFileldName(), ">=", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate lt(T)(EntityFieldInfo info, T t){
        info.assertType!T;
        return new Predicate().addValue(info.getFileldName(), "<", _factory.getDialect().toSqlValue(t));
    }
    public Predicate lt(EntityFieldInfo info){
        return new Predicate().addValue(info.getFileldName(), "<", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }

    public Predicate le(T)(EntityFieldInfo info, T t){
        info.assertType!T;
        return new Predicate().addValue(info.getFileldName(), "<=", _factory.getDialect().toSqlValue(t));
    }
    public Predicate le(EntityFieldInfo info){
        return new Predicate().addValue(info.getFileldName(), "<=", _factory.getDialect().toSqlValue(info.getFieldValue()));
    }
    public Predicate like(EntityFieldInfo info, string pattern) {
        return new Predicate().addValue(info.getFileldName(), "like", _factory.getDialect().toSqlValue(pattern));
    }
    public Predicate notLike(EntityFieldInfo info, string pattern) {
        return new Predicate().addValue(info.getFileldName(), "not like", _factory.getDialect().toSqlValue(pattern));
    }

    

}



