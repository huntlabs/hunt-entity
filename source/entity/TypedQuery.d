
module entity.TypedQuery;

import entity;



class TypedQuery(T) {


    private string _sqlSting;
    private CriteriaQuery!T _query;
    private EntityManager _manager;

    this(CriteriaQuery!T query, EntityManager manager) {
        _query = query;
        _manager = manager;
        _sqlSting = query.toString();
    }

    public T getSingleResult() {
        auto stmt = _manager.getSession().prepare(_sqlSting);
		auto res = stmt.query();
        if(!res.empty()){
			return _query.getRoot().deSerialize((res.front()));
        }
		return null;
    }

    public T[] getResultList() {
        T[] ret;
        auto stmt = _manager.getSession().prepare(_sqlSting);
		auto res = stmt.query();
        foreach(value; res) {
            T t = _query.getRoot().deSerialize((value));
            if (t is null)
                throw new EntityException("getResultList has an null data");
		    ret ~= t;
        }
		return ret;
    }

    
}