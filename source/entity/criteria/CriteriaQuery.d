
module entity.criteria.CriteriaQuery;

import entity;

class CriteriaQuery (T) : CriteriaBase!T {
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    public CriteriaQuery!T select(Root!T root) {
        _sqlBuidler.select("*").from(root.getTableName());
        return this;
    }

    override public CriteriaQuery!T where(Predicate condition) {
        _sqlBuidler.where(condition.toString());
        return this;
    }


}
