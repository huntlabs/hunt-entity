
module entity.TypedQuery;

import entity;



class TypedQuery(T) {


    private string _sqlSting;
    private CriteriaQuery!T _query;
    private EntityManager _manager;

    this(CriteriaQuery!T query, EntityManager manager) {
        _query = query;
        _manager = manager;
    }

    public Object getSingleResult() {
        auto stmt = _manager.getSession().prepare(_query.toString());
		auto res = stmt.query();
        if(!res.empty()){
            long count;
			T t = _query.getRoot().deSerialize(res.front(), count);
            if (t is null && count != 0) {
                return new Long(count);
            }
            return t;
        }
		return null;
    }

    public T[] getResultList() {
        T[] ret;
        auto stmt = _manager.getSession().prepare(_query.toString());
		auto res = stmt.query();
        long count;
        foreach(value; res) {
            T t = _query.getRoot().deSerialize(value, count);
            if (t is null)
                throw new EntityException("getResultList has an null data");
		    ret ~= t;
        }
		return ret;
    }

    public TypedQuery!T setMaxResults(int maxResult) {
        _query.getSqlBuilder().limit(maxResult);
        return this;
    }

    public TypedQuery!T setFirstResult(int startPosition) {
        _query.getSqlBuilder().offset(startPosition);
        return this;
    }
    
}