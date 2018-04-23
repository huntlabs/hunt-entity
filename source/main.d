


import entity;

import std.stdio;




@Table("user")
class User : Entity
{
    @AutoIncrement @PrimaryKey 
    int id;

    string name;
    double money;
    string email;
    bool status;
}


int testCriteriaDelete2(EntityManager manager, CriteriaBuilder builder, User user) {
    CriteriaDelete!User criteriaDelete = builder.createCriteriaDelete!(User);
    Root!User root = criteriaDelete.from(user);
    Predicate c = builder.equal(root.User.id);
    Query!User deleteQuery = manager.createQuery(criteriaDelete.where(c));
    return deleteQuery.executeUpdate();
}


int testCriteriaDelete1(EntityManager manager, CriteriaBuilder builder, int primaryValue) {
    CriteriaDelete!User criteriaDelete = builder.createCriteriaDelete!(User);
    Root!User root = criteriaDelete.from();
    Predicate c = builder.equal(root.User.id, primaryValue);
    Query!User deleteQuery = manager.createQuery(criteriaDelete.where(c));
    return deleteQuery.executeUpdate();
}

int testCriteriaUpdate(EntityManager manager, CriteriaBuilder builder, int primaryValue, int money) {
    CriteriaUpdate!User criteriaUpdate = builder.createCriteriaUpdate!(User);
    Root!User root = criteriaUpdate.from();
    Predicate c = builder.equal(root.User.id, primaryValue);
    Query!User query = manager.createQuery(criteriaUpdate.set(root.User.money, 1000).where(c));
    return query.executeUpdate();
}


User[] testCriteriaQueryOr(EntityManager manager, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)));
    return typedQuery.getResultList();
}

User[] testCriteriaQueryAnd(EntityManager manager, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(builder.and(c1, c2)));
    return typedQuery.getResultList();
}


User testCriteriaQuery2(EntityManager manager, CriteriaBuilder builder, User user) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from(user);
    Predicate c = builder.equal(root.User.id);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(c));
    return typedQuery.getSingleResult();
}

User testCriteriaQuery1(EntityManager manager, CriteriaBuilder builder, int primaryValue) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c = builder.equal(root.User.id, primaryValue);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(c));
    return typedQuery.getSingleResult();
}



int testEntityRemove2(EntityManager manager, int id) {
    return manager.remove!(User)(id);
}

int testEntityRemove1(EntityManager manager, User user) {
    return manager.remove!(User)(user);
}

int testEntityMerge(EntityManager manager, User user, int money) {
    user.money = money;
    return manager.merge!(User)(user);
}

User testEntityFind2(EntityManager manager, User user) {
    return manager.find!(User)(user);
}

User testEntityFind1(EntityManager manager, int id) {
    return manager.find!(User)(id);
}

User testEntityPersist(EntityManager manager, string name, string email, int money) {
    User user = new User();
    user.name = name;
    user.email = email;
    user.money = money;
    manager.persist(user);
    return user;
}



void main() {
    
    DatabaseConfig config = new DatabaseConfig("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql",config);
    EntityManager manager = entityManagerFactory.createEntityManager();
    CriteriaBuilder builder = manager.getCriteriaBuilder();
    manager.getTransaction().begin();

    User u1 = testEntityPersist(manager, "u1", "u1@163.com", 999);
    log("testEntityPersist u1 id ", u1.id);
    
    u1 = testEntityFind1(manager, u1.id);
    log("testEntityFind1 name ", u1.name);

    u1 = testEntityFind2(manager, u1);
    log("testEntityFind2 email ", u1.email);

    int count = testEntityMerge(manager, u1, 1000);
    log("testEntityMerge count ", count);

    User u2 = testEntityPersist(manager, "u2", "u2@163.com", 1001);
    log("testEntityPersist u2 id ", u2.id);

    u2 = testCriteriaQuery1(manager, builder, u2.id);
    log("testCriteriaQuery1 name ", u2.name);

    u2 = testCriteriaQuery2(manager, builder, u2);
    log("testCriteriaQuery2 name ", u2.name);

    User[] u3 = testCriteriaQueryAnd(manager, builder, "u2", "u2@163.com");
    log("testCriteriaQueryAnd u3 length ", u3.length);

    count = testCriteriaUpdate(manager, builder, u3[0].id, cast(int)(u3[0].money+100));
    log("testCriteriaUpdate count ", count);

    
    User[] u4 = testCriteriaQueryOr(manager, builder, "u1", "u2.163.com");
    log("testCriteriaQueryOr u4 length ", u4.length);


    
    
    count = testCriteriaDelete2(manager, builder, u3[0]);
    log("testCriteriaDelete2 count ", count);

    count = testEntityRemove2(manager, u1.id);
    log("testEntityRemove2 count ", count);





    manager.getTransaction().commit();
    // manager.getTransaction().rollback();
    manager.close();
    manager.close();

    


}