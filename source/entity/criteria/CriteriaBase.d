module entity.criteria.CriteriaBase;

import entity;

class CriteriaBase(T) {

    protected Root!T _root;
    protected CriteriaBuilder _criteriaBuilder;
    protected SqlBuilder _sqlBuidler;


    this(CriteriaBuilder criteriaBuilder) {
        _criteriaBuilder = criteriaBuilder;
        _sqlBuidler = criteriaBuilder.createSqlBuilder();
    }

    public Root!T from(T t = null) {
        _root = new Root!(T)(_criteriaBuilder.getDialect(), t); 
        return _root;
    }

    public Root!T getRoot() {return _root;}

    public CriteriaBase!T where(Predicate condition) {
        _sqlBuidler.where(condition.toString());
        return this;
    }

    override public string toString() {
        return _sqlBuidler.build().toString();
    }
}