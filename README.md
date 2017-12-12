## Entity
[Entity](https://github.com/huntlabs/entity) is an object-relational mapping tool for the D programming language. Referring to the design idea of [JPA](https://en.wikipedia.org/wiki/Java_Persistence_API).

## Support databases
 * PostgreSQL 9.0+
 * MySQL 5.1+
 * SQLite 3.7.11+
 
 ## Depends
 * [dbal](https://github.com/huntlabs/dbal)
 * [database](https://github.com/huntlabs/database)

## Simple code
```D
import entity;

@Table("users")
class User
{
    @AutoIncrement
    @PrimaryKey 
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
    EntityManager entitymanager = entityManagerFactory.createEntityManager!(User);

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
     
     //Get a row data from the query condition
     {
        CriteriaBuilder criteria = entitymanager.createCriteriaBuilder!User;
        criteria.where(criteria.gt(criteria.User.id,26762));
        User user = entitymanager.getResult!User(criteria.toString);
     }
     
     //Get multi row data from the query condition
     {
        CriteriaBuilder criteria = entitymanager.createCriteriaBuilder!User;
        criteria.where(criteria.gt(criteria.User.id,26762));
        User[] users = entitymanager.getResultList!User(criteria.toString);
     }
     
     //update multi record by condition
     {
        CriteriaBuilder criteria = entitymanager.createCriteriaBuilder!User;
        criteria.createCriteriaUpdate().set(criteria.User.email,"dakgzhu@foxmail.com")
            .where(criteria.gt(criteria.User.id,26761)).execute();
     }
     
     //remove multi record by condition
     {
        CriteriaBuilder criteria = entitymanager.createCriteriaBuilder!User;
        criteria.createCriteriaDelete().where(criteria.gt(criteria.User.id,26761)).execute();
     }
}
```
