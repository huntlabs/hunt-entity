
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

    public Predicate and(T...)(T args) {
        return new Predicate().andValue(args);
    }

    public Predicate equal(T)(EntityFieldInfo info, T t) {
        return new Predicate().addValue(info.getFileldName(), "=", _factory.getDialect().toSqlValue(t));
    }
    
    


}