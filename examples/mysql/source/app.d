


import entity;

import std.stdio;

@Table("Book")
class Book : Entity{
    mixin GetFunction;

    @AutoIncrement @PrimaryKey 
    long id;

    string name;
    
    @OneToOne(FetchType.LAZY)
    @JoinColumn("book_detail")
    BookDetail detail;


}

@Table("BookDetail")
class BookDetail : Entity{
    mixin GetFunction;

    @AutoIncrement @PrimaryKey 
    long id;

    long numberOfPages;

    @OneToOne(FetchType.LAZY, "detail")
    Book book;


}





@Table("blog")
class Blog  : Entity{

    mixin GetFunction;

    @AutoIncrement @PrimaryKey 
    int id;

    string title;
    string content;

    @ManyToOne(FetchType.EAGER)
    @JoinColumn("uid")
    User user;

    

}


@Table("user")
class User : Entity{
    mixin GetFunction;

    @AutoIncrement @PrimaryKey 
    int id;

    string name;
    double money;
    string email;
    bool status;

    @OneToMany("user", FetchType.LAZY)
    Blog[] blogs;

}



void testOneToOne(EntityManager manager) {
    Book book = manager.find!(Book)(1);
    log("book.name ", book.name);
    log("book.detail.id ", book.detail.id);
    log("book.detail.numberOfPages ", book.detail.numberOfPages);
    log("book.detail.book.id ", book.detail.book.id);
    log("book.detail.book.name ", book.detail.book.name);


    BookDetail detail = manager.find!(BookDetail)(1);
    log("detail.id ", detail.numberOfPages);
    log("detail.book.id ", detail.book.id);
    log("detail.book.name ", detail.book.name);
    log("detail.book.numberOfPages ", detail.book.detail.numberOfPages);
    log("detail.book.detail.id ", detail.book.detail.id);
    log("detail.book.detail.book.name ", detail.book.detail.book.name);
}

User testEntityFind4(EntityManager manager, int id) {
    return manager.find!(User)(id);
}


Blog testEntityFind3(EntityManager manager, int id) {
    return manager.find!(Blog)(id);
}

Blog[] testCriteriaJoin_left(EntityManager manager, CriteriaBuilder builder, string name) {
    CriteriaQuery!Blog criteriaQuery = builder.createQuery!(Blog);
    Root!Blog root = criteriaQuery.from();
    Join!(Blog,User) join = root.join!(User)(root.Blog.user, JoinType.LEFT);
    Predicate p = builder.equal(join.User.name, name);
    criteriaQuery.where(p);
    return manager.createQuery(criteriaQuery.select(root)).getResultList();
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
    Query!User query = manager.createQuery(criteriaUpdate.set(root.User.money, money).where(c));
    return query.executeUpdate();
}

long testCriteriaQuery_count(EntityManager manager, CriteriaBuilder builder) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    criteriaQuery.select(builder.count(root));
    // can test this
    // criteriaQuery.select(builder.count(root.User.id));
    Long ret = cast(Long)(manager.createQuery(criteriaQuery).getSingleResult());
    return ret.longValue();
}

User[] testCriteriaQuery_between(EntityManager manager, CriteriaBuilder builder, int range1, int range2) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    criteriaQuery.select(root);
    Predicate c = builder.between(root.User.money, range1, range2);
    criteriaQuery.where(c);
    return manager.createQuery(criteriaQuery).getResultList();
}

User[] testCriteriaQuery_in(EntityManager manager, CriteriaBuilder builder, string name1, string name2) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    criteriaQuery.select(root);
    Predicate c = builder.In(root.User.name, name1, name2);
    criteriaQuery.where(c);
    return manager.createQuery(criteriaQuery).getResultList();
}



User testCriteriaQuery_multiselect_max_min_avg_sum(EntityManager manager, CriteriaBuilder builder, string name) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    criteriaQuery.multiselect(builder.max(root.User.name), builder.avg(root.User.status), builder.min(root.User.id), builder.sum(root.User.money));
    return cast(User)(manager.createQuery(criteriaQuery).getSingleResult());
}


User[] testCriteriaQuery_Distinct_GroupBy_Having(EntityManager manager, CriteriaBuilder builder) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c = builder.gt(root.User.money, 0);
    criteriaQuery.select(root);
    criteriaQuery.distinct(true);
    criteriaQuery.groupBy(root.User.name);
    criteriaQuery.having(c);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery);
    return typedQuery.getResultList();
}



User[] testCriteriaQueryLike(EntityManager manager, CriteriaBuilder builder, string name, string email, string likeValue) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    Predicate c3 = builder.like(root.User.name, likeValue);
    // Predicate c3 = builder.notLike(root.User.name, likeValue);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2),c3));
    // TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)).where(c3));
    return typedQuery.getResultList();
}

User[] testCriteriaQueryOffsetLimit(EntityManager manager, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.gt(root.User.money, 0);
    criteriaQuery.orderBy(builder.asc(root.User.money), builder.asc(root.User.id));
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)));
    return typedQuery.setFirstResult(1).setMaxResults(1).getResultList();
    
}

User[] testCriteriaQueryOrderBy(EntityManager manager, CriteriaBuilder builder, string name, string email) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    Predicate c1 = builder.equal(root.User.name, name);
    Predicate c2 = builder.equal(root.User.email, email);
    criteriaQuery.orderBy(builder.asc(root.User.money));
    // criteriaQuery.orderBy(builder.desc(root.User.money));
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(builder.or(c1, c2)));
    return typedQuery.getResultList();
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
    return cast(User)(typedQuery.getSingleResult());
}

User testCriteriaQuery1(EntityManager manager, CriteriaBuilder builder, int primaryValue) {
    CriteriaQuery!User criteriaQuery = builder.createQuery!(User);
    Root!User root = criteriaQuery.from();
    //can also use this way
    // Predicate c = builder.equal(root.User.id, primaryValue);
    Predicate c = builder.equal(root.get("id"), primaryValue);
    TypedQuery!User typedQuery = manager.createQuery(criteriaQuery.select(root).where(c));
    return cast(User)(typedQuery.getSingleResult());
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


Blog testEntityFindByClass(EntityManager manager, User user) {
    CriteriaBuilder criteriaBuilder = manager.getCriteriaBuilder();
    CriteriaQuery!Blog criteriaQuery = criteriaBuilder.createQuery!(Blog);
    Root!Blog r = criteriaQuery.from().autoJoin();
    Predicate condition = criteriaBuilder.equal(r.Blog.user, user);
    TypedQuery!Blog query = manager.createQuery(criteriaQuery.select(r).where(condition));
    return cast(Blog)(query.getSingleResult());
}


void main() {
    
    // DatabaseConfig config = new DatabaseConfig("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
    // DatabaseConfig config = new DatabaseConfig("mysql://root:@10.1.11.167:3306/huntblog2?charset=utf-8");
    // DatabaseConfig config = new DatabaseConfig("postgresql://postgres:123456@0.0.0.0:5432/huntblog?charset=utf-8");

    EntityOption option = new EntityOption();
    option.database.driver = "mysql";
    option.database.host = "10.1.11.167";
    option.database.port = 3306;
    option.database.database = "huntblog2";
    option.database.username = "root";
    option.database.password = "";
    // option.database.prefix = "test_";
    
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql", option);

    EntityManager manager = entityManagerFactory.createEntityManager();
    CriteriaBuilder builder = manager.getCriteriaBuilder();
    manager.getTransaction().begin();

    User u1 = testEntityPersist(manager, "u1", "u1@163.com", 999);
    log("testEntityPersist u1 id ", u1.id);
    
    u1 = testEntityFind1(manager, u1.id);
    log("testEntityFind1 name ", u1.name);

    u1 = testEntityFind2(manager, u1);
    log("testEntityFind2 email ", u1.email);

    int count ;
    count = testEntityMerge(manager, u1, 888);
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

    
    User[] u4 = testCriteriaQueryOr(manager, builder, "u1", "u2@163.com");
    log("testCriteriaQueryOr u4 length ", u4.length);

    u4 = testCriteriaQueryOrderBy(manager, builder, "u1", "u2@163.com");
    log("testCriteriaQueryOrderBy u4 ", u4[0].money);

    u4 = testCriteriaQueryOffsetLimit(manager, builder, "u1", "u2@163.com");
    log("testCriteriaQueryOffsetLimit u4 ", u4[0].money);

    u4 = testCriteriaQueryLike(manager, builder, "u1", "u2@163.com", "u%");
    log("testCriteriaQueryLike u4[0] money ", u4[0].money);
    log("testCriteriaQueryLike u4[1] money ", u4[1].money);
    
    u4 = testCriteriaQuery_Distinct_GroupBy_Having(manager, builder);
    log("testCriteriaQuery_Distinct_GroupBy_Having u4 length ", u4.length);


    User u5 = testCriteriaQuery_multiselect_max_min_avg_sum(manager, builder, "u1");
    log("testCriteriaQuery_multiselect_max_min_avg_sum u5 name = %s,money = %s,id = %s ".format(u5.name, u5.money, u5.id));

    count = cast(int)testCriteriaQuery_count(manager, builder);
    log("testCriteriaQuery_count u5 length ", count);

    u4 = testCriteriaQuery_between(manager, builder, 100, 200);
    log("testCriteriaQuery_between u4 length ", u4.length);


    u4 = testCriteriaQuery_in(manager, builder, "u1", "u2");
    log("testCriteriaQuery_in u4 length ", u4.length);

    Blog b1 = new Blog();
    b1.user = u1;
    b1.content = "u1-blog1-content";
    manager.persist(b1);
    
    Blog b2 = new Blog();
    b2.user = u1;
    b2.content = "u2-blog2-content";
    manager.persist(b2);
    

    Blog[] blogs = testCriteriaJoin_left(manager, builder, "u1");
    log("testCriteriaJoin_left blogs length ", blogs.length);
    log("null = ",blogs[0].user is null);
    log(blogs[0].getUser());
    log(blogs[0].user.email);
    log("blogs.user.name1 = ", blogs[0].getUser().email);
    log("blogs.user.name2 = ", blogs[1].getUser().email);

    Blog blog = testEntityFind3(manager, b1.id);
    log("testEntityFind3 name ", blog.getUser().name);
    log("testEntityFind3  ", blog.user.getBlogs()[0].id);
    log("testEntityFind3  ", blog.user.blogs[1].id);
    log("testEntityFind3  ", blog.user.blogs[0].content);
    log("testEntityFind3  ", blog.user.blogs[1].content);
    log("testEntityFind3  ", blog.user.blogs[0].getUser().id);
    log("testEntityFind3  ", blog.user.blogs[1].user.id);
    log("testEntityFind3  ", blog.user.blogs[0].user.name);
    log("testEntityFind3  ", blog.user.blogs[1].user.name);

    u5 = testEntityFind4(manager, u1.id);
    u5.getBlogs();
    u5.getBlogs()[0].getUser();
    u5.getBlogs()[1].getUser();
    log("testEntityFind4 user.blogs.length ", u5.blogs.length);
    log("testEntityFind4 ",u5.id);
    log("testEntityFind4 ",u5.name);
    log("testEntityFind4 ",u5.blogs[0].id);
    log("testEntityFind4 ",u5.blogs[1].id);
    log("testEntityFind4 ",u5.blogs[0].content);
    log("testEntityFind4 ",u5.blogs[1].content);

    log("testEntityFind4 ",u5.blogs[0].user.id);
    log("testEntityFind4 ",u5.blogs[1].user.id);
    log("testEntityFind4 ",u5.blogs[0].user.name);
    log("testEntityFind4 ",u5.blogs[1].user.name);
    log("testEntityFind4 ",u5.blogs[0].user.blogs[0].id);
    log("testEntityFind4 ",u5.blogs[0].user.blogs[1].id);
    log("testEntityFind4 ",u5.blogs[1].user.blogs[0].content);
    log("testEntityFind4 ",u5.blogs[1].user.blogs[1].content);
    
    blog = testEntityFindByClass(manager, blog.user);

    count = manager.remove!(Blog)(b1);
    log("em.remove b1 count ", count);

    count = manager.remove!(Blog)(b2);
    log("em.remove b2 count ", count);
    

    count = testCriteriaDelete2(manager, builder, u3[0]);
    log("testCriteriaDelete2 count ", count);

    count = testEntityRemove2(manager, u1.id);
    log("testEntityRemove2 count ", count);


    BookDetail detail = new BookDetail();
    detail.numberOfPages = 1;
    manager.persist(detail);

    Book book = new Book();
    book.name = "book1";
    book.detail = detail;
    manager.persist(book);

    book = manager.find!(Book)(book.id);
    assert(book.detail is null, "book.detail is null");
    assert(book.getDetail().numberOfPages, "book.getDetail().numberOfPages");
    

    detail = manager.find!(BookDetail)(detail.id);
    assert(detail.book is null, "detail.book is null ");
    assert(detail.getBook().id, "detail.getBook().id ");
    
    

    
    manager.remove!(Book)(book);
    manager.remove!(BookDetail)(detail);




    manager.getTransaction().commit();
    // manager.getTransaction().rollback();
    manager.close();
    entityManagerFactory.close();


}
