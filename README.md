entity is ORM for D language (similar to Hibernate)

Use SQLite 3.7.11 or later. 
Use Mysql 5.1 or later.
Use pgsql 9.0 or later.
In older versions is not supported.

## Quick Start
```D
import entity;

@Table("user")
class User
{
    @AutoIncrement @PrimaryKey 
    int id;

    string name;
    float money;
    string email;
    bool status;
}

void main()
{
    DatabaseConfig config = new DatabaseConfig("postgresql://postgres:postgres@127.0.0.1:5432/test?charset=utf-8");
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("pgsql",config);
    EntityManager entitymanager = entityManagerFactory.createEntityManager!(User,Blog);

    //insert
    {
      User user = new User();
      user.name = "viile";
      user.money = 10.5;
      user.status = true;
      entitymanager.persist(user);
    }

    //remove by primary key
    {
      User user = new User();
      user.id = 26760;
      entitymanager.remove(user);
     }

    //find by primary key
    {
      User user = new User();
      user.id = 26760;
      if(entitymanager.find(user) is null){
        writeln("user not found");
      }
     }

    //update by primary key
    {
      User user = new User();
      user.id = 26760;
      user.email = "viile@foxmail.com";
      entitymanager.merge(user);
     }
}
```
