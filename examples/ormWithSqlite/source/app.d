import std.stdio;

import entity;

import std.json;

/*
CREATE TABLE user(id integer primary key autoincrement,name varchar(255),money double,email varchar(255),status integer);
*/
@Table("user")
class User : Entity
{
    @AutoIncrement @PrimaryKey 
    int id;

    @NotNull
    string name;
    float money;
    string email;
    bool status;

}

/*
CREATE TABLE blog(id integer primary key autoincrement,uid integer,title varchar(255),content varchar(255));
*/
@Table("blog")
class Blog : Entity
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
    DatabaseConfig config = new DatabaseConfig("sqlite:///./testDB.db");
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("sqlite",config);
    EntityManager entitymanager = entityManagerFactory.createEntityManager!(User,Blog);

    //Dialect dialect = new MysqlDialect();

    //insert
    User user = new User();
    user.name = "viile";
    user.money = 10.5;
    user.email = "viile@dlang.org";
    user.status = true;

    //auto r = entitymanager.findEntityForObject(user).getPrimaryKeyValue!int(user);
    //writeln(r);

    entitymanager.persist(user);

    CriteriaBuilder criteria = entitymanager.createCriteriaBuilder!User;
    User[] users = entitymanager.getResultList!User(criteria);

    foreach(_user;users){
        writeln(_user.id);
    }
    

    /*
    auto session = entitymanager.createEntityTransaction();

    User user1 = new User();
    user1.name = "user1";
    user1.money = 0;
    user1.email = "test";
    user1.status = false;
    User user2 = new User();
    user2.name = "user2";
    user2.money = 0;
    user2.email = "test";
    user2.status = true;

    session.persist(user1);
    session.persist(user2);
    //session.commit();
    session.rollback();

    */
    //writeln(user.id);

    //auto t = cast(User)entitymanager.find!(User,int)(25);
    //writeln(t.name);
    
    //int r = entitymanager.remove!(User,int)(28);
    //writeln(r);
    
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

