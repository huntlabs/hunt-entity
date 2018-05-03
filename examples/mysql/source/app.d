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

int testCriteriaDelete2(EntityManager em, CriteriaBuilder builder, User user) {
    CriteriaDelete!User criteriaDelete = builder.createCriteriaDelete!(User);
    Root!User root = criteriaDelete.from(user);
    Predicate c = builder.equal(root.User.id);
    Query!User deleteQuery = em.createQuery(criteriaDelete.where(c));
    return deleteQuery.executeUpdate();
}

int testCriteriaDelete1(EntityManager em, CriteriaBuilder builder, int primaryValue) {
    CriteriaDelete!User criteriaDelete = builder.createCriteriaDelete!(User);
    Root!User root = criteriaDelete.from();
    Predicate c = builder.equal(root.User.id, primaryValue);
    Query!User deleteQuery = em.createQuery(criteriaDelete.where(c));
    return deleteQuery.executeUpdate();
}

int testCriteriaUpdate(EntityManager em, CriteriaBuilder builder, int primaryValue, int money) {
    CriteriaUpdate!User criteriaUpdate = builder.createCriteriaUpdate!(User);
    Root!User root = criteriaUpdate.from();
    Predicate c = builder.equal(root.User.id, primaryValue);
    Query!User query = em.createQuery(criteriaUpdate.set(root.User.money, money).where(c));
    return query.executeUpdate();
}

long testCriteriaQuery_count(EntityManager em, CriteriaBuilder builder) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    criteriaQuery.select(builder.count(root));
    // can test this
    // criteriaQuery.select(builder.count(root.User.id));
    Long ret = cast(Long)(em.createQuery(criteriaQuery).getSingleResult());
    return ret.longValue();
}

User testCriteriaQuery_multiselect_max_min_avg_sum(EntityManager em, CriteriaBuilder builder, string name) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    criteriaQuery.multiselect(builder.max(root.User.name), builder.avg(root.User.status), builder.min(root.User.id), builder.sum(root.User.money));
    return cast(User)(em.createQuery(criteriaQuery).getSingleResult());
}

User[] testCriteriaQuery_Distinct_GroupBy_Having(EntityManager em, CriteriaBuilder builder) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c = builder.gt(root.User.money, 0);
    criteriaQuery.select(root);
    criteriaQuery.distinct(true);
    criteriaQuery.groupBy(root.User.name);
    criteriaQuery.having(c);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery);
    return typedQuery.getResultList();
}

User[] testCriteriaQueryLike(EntityManager em, CriteriaBuilder builder, string name, string email, string likeValue) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    Predicate c3 = builder.like(root.User.name, likeValue);
    // Predicate c3 = builder.notLike(root.User.name, likeValue);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2),c3));
    // TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)).where(c3));
    return typedQuery.getResultList();
}

User[] testCriteriaQueryOffsetLimit(EntityManager em, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.gt(root.User.money, 0);
    criteriaQuery.orderBy(builder.asc(root.User.money), builder.asc(root.User.id));
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)));
    return typedQuery.setFirstResult(0).setMaxResults(1).getResultList();
}

User[] testCriteriaQueryOrderBy(EntityManager em, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    criteriaQuery.orderBy(builder.asc(root.User.money));
    // criteriaQuery.orderBy(builder.desc(root.User.money));
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)));
    return typedQuery.getResultList();
}

User[] testCriteriaQueryOr(EntityManager em, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)));
    return typedQuery.getResultList();
}

User[] testCriteriaQueryAnd(EntityManager em, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.and(c1, c2)));
    return typedQuery.getResultList();
}

User testCriteriaQuery2(EntityManager em, CriteriaBuilder builder, User user) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from(user);
    Predicate c = builder.equal(root.User.id);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(c));
    return cast(User)(typedQuery.getSingleResult());
}

User testCriteriaQuery1(EntityManager em, CriteriaBuilder builder, int primaryValue) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c = builder.equal(root.User.id, primaryValue);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(c));
    return cast(User)(typedQuery.getSingleResult());
}

int testEntityRemove2(EntityManager em, int id) {
    return em.remove!(User)(id);
}

int testEntityRemove1(EntityManager em, User user) {
    return em.remove!(User)(user);
}

int testEntityMerge(EntityManager em, User user, int money) {
    user.money = money;
    return em.merge!(User)(user);
}

User testEntityFind2(EntityManager em, User user) {
    return em.find!(User)(user);
}

User testEntityFind1(EntityManager em, int id) {
    return em.find!(User)(id);
}

User testEntityPersist(EntityManager em, string name, string email, int money) {
    User user = new User();
    user.name = name;
    user.email = email;
    user.money = money;
    em.persist(user);
    return user;
}

void main()
{
    DatabaseOption options = new DatabaseOption("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("default", options);
    EntityManager em = entityManagerFactory.createEntityManager();
    CriteriaBuilder builder = em.getCriteriaBuilder();
    em.getTransaction().begin();

    User u1 = testEntityPersist(em, "u1", "u1@163.com", 999);
    log("testEntityPersist u1 id ", u1.id);
    
    u1 = testEntityFind1(em, u1.id);
    log("testEntityFind1 name ", u1.name);

    u1 = testEntityFind2(em, u1);
    log("testEntityFind2 email ", u1.email);

    int count = testEntityMerge(em, u1, 888);
    log("testEntityMerge count ", count);

    User u2 = testEntityPersist(em, "u2", "u2@163.com", 1001);
    log("testEntityPersist u2 id ", u2.id);

    u2 = testCriteriaQuery1(em, builder, u2.id);
    log("testCriteriaQuery1 name ", u2.name);

    u2 = testCriteriaQuery2(em, builder, u2);
    log("testCriteriaQuery2 name ", u2.name);

    User[] u3 = testCriteriaQueryAnd(em, builder, "u2", "u2@163.com");
    log("testCriteriaQueryAnd u3 length ", u3.length);

    count = testCriteriaUpdate(em, builder, u3[0].id, cast(int)(u3[0].money+100));
    log("testCriteriaUpdate count ", count);

    
    User[] u4 = testCriteriaQueryOr(em, builder, "u1", "u2.163.com");
    log("testCriteriaQueryOr u4 length ", u4.length);

    u4 = testCriteriaQueryOrderBy(em, builder, "u1", "u2.163.com");
    log("testCriteriaQueryOrderBy u4 ", u4[0].money);

    u4 = testCriteriaQueryOffsetLimit(em, builder, "u1", "u2.163.com");
    log("testCriteriaQueryOffsetLimit u4 ", u4[0].money);

    u4 = testCriteriaQueryLike(em, builder, "u1", "u2.163.com", "u%");
    log("testCriteriaQueryLike u4[0] money ", u4[0].money);
    log("testCriteriaQueryLike u4[1] money ", u4[1].money);
    
    u4 = testCriteriaQuery_Distinct_GroupBy_Having(em, builder);
    log("testCriteriaQuery_Distinct_GroupBy_Having u4 length ", u4.length);


    User u5 = testCriteriaQuery_multiselect_max_min_avg_sum(em, builder, "u1");
    log("testCriteriaQuery_multiselect_max_min_avg_sum u5 name = %s,money = %s,id = %s ".format(u5.name, u5.money, u5.id));

    count = cast(int)testCriteriaQuery_count(em, builder);
    log("testCriteriaQuery_count u5 length ", count);

    count = testCriteriaDelete2(em, builder, u3[0]);
    log("testCriteriaDelete2 count ", count);

    count = testEntityRemove2(em, u1.id);
    log("testEntityRemove2 count ", count);

    //todo between /*top*/ in join union (select into) (FOREIGN KEY)
    //todo first last

    em.getTransaction().commit();
    // em.getTransaction().rollback();
    em.close();
    entityManagerFactory.close();
}
