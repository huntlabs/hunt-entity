module entity.criteria.CriteriaUpdate;

import entity;

class CriteriaUpdate(T) : CriteriaBase!T{
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!T from(T t = null) {
        super.from(t);
        _sqlBuidler.update(_root.getTableName());
        return _root;
    }
    //P = Predicate
    public CriteriaUpdate!T where(P...)(P predicates) {
        return cast(CriteriaUpdate!T)super.where(predicates);
    }
    public CriteriaUpdate!T set(P)(EntityFieldInfo field, P p) {
        field.assertType!P;
        _sqlBuidler.set(field.getFileldName(), _criteriaBuilder.getDialect().toSqlValue(p));
        return this;
    }

    public CriteriaUpdate!T set(EntityFieldInfo field) {
        _sqlBuidler.set(field.getFileldName(), _criteriaBuilder.getDialect().toSqlValue(field.getFieldValue()));
        return this;
    }
    
}