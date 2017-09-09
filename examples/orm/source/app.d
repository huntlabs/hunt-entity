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
    DatabaseConfig config = new DatabaseConfig("postgresql://postgres:123456@10.1.11.44:5432/test?charset=utf-8");
    config.setMaximumConnection = 1;
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("pgsql",config);
    EntityManager entitymanager = entityManagerFactory.createEntityManager!(User,Blog);

    Dialect dialect = new MysqlDialect();

    //insert
    User user = new User();
    user.name = "viile";
    user.money = 10.5;
    user.status = true;
    entitymanager.persist(user);

    writeln(user.id);

    auto t = cast(User)entitymanager.find!(User,int)(25);
    writeln(t.name);
    
    int r = entitymanager.remove!(User,int)(28);
    writeln(r);
    
    /*
    //remove
    //entitymanager.remove(user);

    //find
    user.id = 26760;
    entitymanager.find(user);

    //auto user = entitymanager.find!User(1);

    writeln(user.name,"-",user.money,"-",user.email,"-",user.status);

    //update
    user.email = "viile@foxmail.com";
    entitymanager.merge(user);
    writeln(user.name,"-",user.money,"-",user.email,"-",user.status);

    //get multi record
    auto builder = entitymanager.createSqlBuilder();
    builder.select("*")
        .from("user")
        .where("id > 1");
    User[] users = entitymanager.getResultList!User(builder);

    foreach(u;users){
        writeln(u.name,"-",u.money,"-",u.email,"-",u.status);
    }
    */
}

