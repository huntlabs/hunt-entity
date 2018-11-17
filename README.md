[![Build Status](https://travis-ci.org/huntlabs/hunt-entity.svg?branch=master)](https://travis-ci.org/huntlabs/hunt-entity)

## Entity
[Entity](https://github.com/huntlabs/entity) is an object-relational mapping tool for the D programming language. Referring to the design idea of [JPA](https://en.wikipedia.org/wiki/Java_Persistence_API).

## Support databases
 * PostgreSQL 9.0+
 * MySQL 5.1+
 * SQLite 3.7.11+
 
## Depends
 * [hunt-database](https://github.com/huntlabs/hunt-database)
 * [hunt-sql](https://github.com/huntlabs/hunt-sql)

## Simple code
```D
import hunt.entity;

@Table("user")
class User
{
    mixin MakeEntity;

    @PrimaryKey
    @AutoIncrement
    int id;

    string name;
    double money;
    string email;
    bool status;
}

void main()
{
    auto option = new EntityOption;

    option.database.driver = "mysql";
    option.database.host = "localhost";
    option.database.port = 3306;
    option.database.database = "test";
    option.database.username = "root";
    option.database.password = "123456";
    option.database.charset = "utf8mb4";
    option.database.prefix = "hunt_";

    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("default", option);
    EntityManager em = entityManagerFactory.createEntityManager();

    // begin transaction
    em.getTransaction().begin();

    // define your database existing row id in here
    int id = 10;

    auto user = em.find!User(id);
    log("User name is: ", user.name);

    // commit transaction
    em.getTransaction().commit();

    em.close();
    entityManagerFactory.close();
}
```

## Insert row
```D
    auto user = new User();
    user.name = "Brian";
    user.email = "brian@huntlabs.cn";
    user.money = 99.9;
    
    // insert user
    em.persist(user);
    log("User id is: ", user.id);
```

## Delete row
```D
    int n = em.remove!User(id);
    log("The number of users deleted is: ", n);
```

## Update row
```D
    auto user = em.find!User(id);
    log("User name is: ", user.name);
    user.name = "zoujiaqing";
    em.merge!User(user);
    log("The number of users updated is: ", n);
```

## Use CriteriaQuery to find
```D
    // create CriteriaBuilder object from em
    CriteriaBuilder builder = em.getCriteriaBuilder();

    CriteriaQuery!User criteriaQuery = builder.createQuery!User;
    Root!User root = criteriaQuery.from();
    Predicate p1 = builder.equal(root.User.id, id);
    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(p1));

    auto user = typedQuery.getSingleResult();

    log("User name is: ", user.name);
```

## Use CriteriaQuery to Multi-condition find
```D
    // create CriteriaBuilder object from em
    CriteriaBuilder builder = em.getCriteriaBuilder();

    CriteriaQuery!User criteriaQuery = builder.createQuery!User;
    Root!User root = criteriaQuery.from();

    Predicate p1 = builder.lt(root.User.id, 1000);  // User id is less than 1000.
    Predicate p2 = builder.gt(root.User.money, 0);  // User money is greater than 0.
    Predicate p3 = builder.like(root.User.name, "z%");  // User name prefix is z.

    TypedQuery!User typedQuery = em.createQuery(criteriaQuery.select(root).where(builder.and(p1, p2), p3));
    User[] users = typedQuery.getResultList();

    log("The number of users found is: ", users.length);
```
