
module entity.criteria.CriteriaQuery;

import entity;

class CriteriaQuery (T) : CriteriaBase!T {
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    public CriteriaQuery!T select(Root!T root) {
        _sqlBuidler.select("*");
        return this;
    }
    //P = Predicate
    public CriteriaQuery!T where(P...)(P predicates) {
        return cast(CriteriaQuery!T)super.where(predicates);
    }
    //O = Order
    public CriteriaQuery!T orderBy(O...)(O orders) {
        foreach(v; orders) {
            _sqlBuidler.orderBy(v.getColume(), v.getOrderType());
        }
        return this;
    }

    //P = Predicate
    public CriteriaQuery!T groupBy(P...)(P predicates) {
        foreach(v; predicates) {
            _sqlBuidler.groupBy(v.getColumnName());
        }
        return this;
    }




    public CriteriaQuery!T distinct(bool distinct) {
        _sqlBuidler.setDistinct(distinct);
        return this;
    }


    public SqlBuilder getSqlBuilder() {return _sqlBuidler;}
    
}
