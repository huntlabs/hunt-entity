module entity.Query;

import entity;


class Query(T) {

    private string _sqlSting;
    private CriteriaBase!T _criteria;
    private EntityManager _manager;

    this(CriteriaBase!T criteria, EntityManager manager) {
        _criteria = criteria;
        _manager = manager;
        _sqlSting = criteria.toString();
    }

    public int executeUpdate() {
        auto stmt = _manager.getSession().prepare(_sqlSting); 
        //TODO update 时 返回的row line count 为 0
        return stmt.execute();
    }

}