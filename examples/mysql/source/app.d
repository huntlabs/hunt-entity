


import hunt.entity;

import std.stdio;

import SqlStruct.User;
import SqlStruct.Blog;
import SqlStruct.Book;
import SqlStruct.BookDetail;



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

int testEntityMerge(EntityManager manager, User user, double money) {
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
    Root!Blog r = criteriaQuery.from();
    Predicate condition = criteriaBuilder.equal(r.Blog.user, user);
    TypedQuery!Blog query = manager.createQuery(criteriaQuery.select(r).where(condition));
    return cast(Blog)(query.getSingleResult());
}


void main() {

    writeln("*****Note : This example may not run correctly , please use 'examples/EntityTest'*****");

    EntityOption option = new EntityOption();
    option.database.driver = "mysql";
    option.database.host = "10.1.11.167";
    option.database.port = 3306;
    option.database.database = "huntblog2";
    option.database.username = "root";
    option.database.password = "";
    //can add table prefix "test_" means table name is "test_user";
    option.database.prefix = "";

    
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql", option);

    //active create tables;
    entityManagerFactory.createTables!(User,Blog,Book,BookDetail);

    EntityManager manager = entityManagerFactory.createEntityManager();
    CriteriaBuilder builder = manager.getCriteriaBuilder();
    
    //transaction begin
    manager.getTransaction().begin();
    try {
        User u1 = testEntityPersist(manager, "u1", "u1@163.com", 999);
        assert(u1.id != 0, "testEntityPersist error");
        
        u1 = testEntityFind1(manager, u1.id);
        assert(u1.name == "u1", "testEntityFind1 error");

        u1 = testEntityFind2(manager, u1);
        assert(u1.email == "u1@163.com", "testEntityFind2 error");

        int count ;
        count = testEntityMerge(manager, u1, 888);
        assert(u1.money == 888 && count == 1, "testEntityMerge error");

        u1 = testCriteriaQuery1(manager, builder, u1.id);
        assert(u1.name == "u1", "testCriteriaQuery1 error");

        u1 = testCriteriaQuery2(manager, builder, u1);
        assert(u1.name == "u1", "testCriteriaQuery2 error");

        User[] u2 = testCriteriaQueryAnd(manager, builder, "u1", "u1@163.com");
        assert(u2.length == 1, "testCriteriaQueryAnd error");

        count = testCriteriaUpdate(manager, builder, u2[0].id, cast(int)(u2[0].money+100));
        assert(count == 1, "testCriteriaUpdate error");

        User u3 = testEntityPersist(manager, "u2", "u2@163.com", 1001);

        u2 = testCriteriaQueryOr(manager, builder, "u1", "u2@163.com");
        assert(u2.length == 2, "testCriteriaQueryOr error");

        u2 = testCriteriaQueryOrderBy(manager, builder, "u1", "u2@163.com");
        assert(u2[0].money == 988, "testCriteriaQueryOrderBy error");

        u2 = testCriteriaQueryOffsetLimit(manager, builder, "u1", "u2@163.com");
        assert(u2[0].money == 1001, "testCriteriaQueryOffsetLimit error");


        u2 = testCriteriaQueryLike(manager, builder, "u1", "u2@163.com", "u%");
        assert(u2[0].money == 988, "testCriteriaQueryLike error");
        assert(u2[1].money == 1001, "testCriteriaQueryLike error");

        u2 = testCriteriaQuery_Distinct_GroupBy_Having(manager, builder);
        assert(u2.length == 2, "testCriteriaQuery_Distinct_GroupBy_Having error");


        u1 = testCriteriaQuery_multiselect_max_min_avg_sum(manager, builder, "u1");
        assert(u1.money == 988+1001, "testCriteriaQuery_multiselect_max_min_avg_sum error");

        count = cast(int)testCriteriaQuery_count(manager, builder);
        assert(count == 2, "testCriteriaQuery_count error");

        u2 = testCriteriaQuery_between(manager, builder, 900, 1000);
        assert(u2[0].name == "u1", "testCriteriaQuery_between error");


        u2 = testCriteriaQuery_in(manager, builder, "u1", "u2");
        assert(u2.length == 2, "testCriteriaQuery_in error");


        Blog b1 = new Blog();
        b1.user = u1;
        b1.content = "u1-blog1-content";
        manager.persist(b1);
        
        Blog b2 = new Blog();
        b2.user = u1;
        b2.content = "u2-blog2-content";
        manager.persist(b2);
        

        Blog[] blogs = testCriteriaJoin_left(manager, builder, "u1");
        assert(blogs.length == 2, "testCriteriaJoin_left error");
        assert(blogs[0].user is null, "testCriteriaJoin_left error");
        //class blog.user set been FetchType.LAZY, should active use getXXX function to load the lazy data.
        assert(blogs[0].getUser().email == "u1@163.com", "testCriteriaJoin_left error");
        assert(blogs[1].getUser().email, "testCriteriaJoin_left error");


        Blog blog = testEntityFind3(manager, b1.id);
        assert(blog.getUser().name == "u1", "testEntityFind3 error");
        assert(blog.user.getBlogs()[0].id == b1.id, "testEntityFind3 error");
        assert(blog.user.blogs[1].id == b2.id, "testEntityFind3 error");
        assert(blog.user.blogs[0].content == "u1-blog1-content", "testEntityFind3 error");
        assert(blog.user.blogs[1].content == "u2-blog2-content", "testEntityFind3 error");
        assert(blog.user.blogs[0].getUser().id == u1.id, "testEntityFind3 error");
        assert(blog.user.blogs[0].user.name == "u1", "testEntityFind3 error");


        u1 = testEntityFind4(manager, u1.id);
        u1.getBlogs();
        u1.getBlogs()[0].getUser();
        u1.getBlogs()[1].getUser();

        assert(u1.name == "u1", "testEntityFind4 error");
        assert(u1.blogs[0].id == b1.id, "testEntityFind4 error");
        assert(u1.blogs[1].id == b2.id, "testEntityFind4 error");
        assert(u1.blogs[0].content == b1.content, "testEntityFind4 error");
        assert(u1.blogs[1].content == b2.content, "testEntityFind4 error");

        assert(u1.blogs[0].user.blogs[0].id == b1.id, "testEntityFind4 error");
        assert(u1.blogs[0].user.blogs[1].id == b2.id, "testEntityFind4 error");
        assert(u1.blogs[1].user.blogs[0].content == b1.content, "testEntityFind4 error");
        assert(u1.blogs[1].user.blogs[1].content == b2.content, "testEntityFind4 error");

        assert(blog.getUser().name == "u1", "testEntityFind4 error");
        assert(blog.getUser().name == "u1", "testEntityFind4 error");
        
        blog = testEntityFindByClass(manager, blog.user);
        assert(blog.getUser().name == "u1", "testEntityFindByClass error");


        count = manager.remove!(Blog)(b1);
        assert(count == 1, "manager.remove error");

        count = manager.remove!(Blog)(b2);
        assert(count == 1, "manager.remove error");


        count = testCriteriaDelete2(manager, builder, u3);
        assert(count == 1, "testCriteriaDelete2 error");

        count = testEntityRemove2(manager, u1.id);
        assert(count == 1, "testEntityRemove2 count ");


        BookDetail detail = new BookDetail();
        detail.numberOfPages = 1;
        manager.persist(detail);

        Book book = new Book();
        book.name = "book1";
        book.detail = detail;
        manager.persist(book);

        book = manager.find!(Book)(book.id);
        assert(book.detail !is null, "book.detail is null");
        assert(book.getDetail().numberOfPages, "book.getDetail().numberOfPages");
        

        detail = manager.find!(BookDetail)(detail.id);
        assert(detail.book is null, "detail.book is null ");
        assert(detail.getBook().id, "detail.getBook().id ");
        
        manager.remove!(Book)(book);
        manager.remove!(BookDetail)(detail);



        manager.getTransaction().commit();
    }
    catch(Exception e) {
        manager.getTransaction().rollback();
        log(e);
    }

    manager.close();
    entityManagerFactory.close();


}
