
module entity.criteria.CriteriaQuery;

import entity;

class CriteriaQuery (T) : CriteriaBase!T {
    this(CriteriaBuilder criteriaBuilder) {
        super(criteriaBuilder);
    }
    public CriteriaQuery!T select(Root!T root) {
        _sqlBuidler.select(["*"]);
        return this;
    }
    public CriteriaQuery!T select(EntityFieldInfo info) {
        _sqlBuidler.select([info.getFullColumeString()]);
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
    //P = Predicate
    public CriteriaQuery!T having(P...)(P predicates) { 
        string s;
        foreach(k, v; predicates) {
            s ~= v.toString();
            if (k != predicates.length-1) 
                s ~= " AND ";
        }
        _sqlBuidler.having(s);
        return this;
    }
    //E = EntityFieldInfo
    public CriteriaQuery!T multiselect(E...)(E entityFieldInfos) {
        string[] columes;
        foreach(v; entityFieldInfos) {
            columes ~= v.getFullColumeString();
        }
        _sqlBuidler.select(columes);
        return this;
    }

    public CriteriaQuery!T distinct(bool distinct) {
        _sqlBuidler.setDistinct(distinct);
        return this;
    }


    public SqlBuilder getSqlBuilder() {return _sqlBuidler;}
    
}
