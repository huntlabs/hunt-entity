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

    override public CriteriaUpdate!T where(Predicate condition) {
        _sqlBuidler.where(condition.toString());
        return this;
    }

    public CriteriaUpdate!T set(P)(EntityFieldInfo field, P p) {
        _sqlBuidler.set(field.getFileldName(), _criteriaBuilder.getDialect().toSqlValue(p));
        return this;
    }
    
}