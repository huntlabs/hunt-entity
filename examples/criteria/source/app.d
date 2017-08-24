import std.stdio;

import entity;

import std.json;

@Table("user")
class User
{
    @AutoIncrement @PrimaryKey 
    int id;

    @NotNull
    string name;
    float money;
    string email;
    bool status;

}

@Table("blog")
class Blog
{
    @AutoIncrement @PrimaryKey
    int id;
    int uid;

    string title;
    string context;
}

void main()
{
    writeln("Edit source/app.d to start your project.");
    DatabaseConfig config = new DatabaseConfig("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
    config.setMaximumConnection = 1;
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql",config);
    EntityManager entitymanager = entityManagerFactory.createEntityManager!(User,Blog);

    CriteriaBuilder criteria = entitymanager.createCriteriaBuilder!User;
    with(criteria){
        where(
            expr.andX(
                expr.eq(criteria.User.money, 10.5),
                expr.eq(criteria.User.status, true),
                )

            );
    }
    User[] users = entitymanager.getResultList!User(criteria.toString);
    foreach(user;users){
        writeln(user.id);
    }

    CriteriaBuilder cb = entitymanager.createCriteriaBuilder!User;
    cb.createCriteriaDelete().where(cb.eq(cb.User.id,26802)).execute();

    CriteriaBuilder cb2 = entitymanager.createCriteriaBuilder!User;
    cb2.createCriteriaUpdate()
    .set(cb2.User.email,"viile@gamil.com")
    .where(cb2.gt(cb2.User.id,26761)).execute();
}

