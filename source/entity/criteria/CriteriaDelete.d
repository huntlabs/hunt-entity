

module entity.criteria.CriteriaDelete;

import entity;

class CriteriaDelete(T) : CriteriaBase!T {
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    override public Root!T from(T t = null) {
        super.from(t);
        _sqlBuidler.remove(_root.getTableName());
        return _root;
    }

    override public CriteriaDelete!T where(Predicate condition) {
        return cast(CriteriaDelete!T)super.where(condition);
    }
}