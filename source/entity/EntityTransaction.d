module entity.EntityTransaction;

import entity;

class EntityTransaction {
    

    private EntityManager _entityManager;
    private bool _isOnTrans;
    private Transaction _tran;

    this(EntityManager entityManager) { 
        _entityManager = entityManager;
    }
    
    public void begin() {
        _entityManager.getSession().beginTransaction();
    }

    public void commit() {
        _entityManager.getSession().commit();
    }

    public void rollback() {
        _entityManager.getSession().rollback();
    }
}