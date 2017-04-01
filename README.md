Entity
==========

Entity is ORM for D language (similar to JPA, fork from hibernated)

Uses DDBC as DB abstraction layer: https://github.com/buggins/ddbc

Available as DUB package

Use SQLite 3.7.11 or later. In older versions syntax INSERT INTO (col1, col2) VALUES (1, 2), (3, 4) is not supported.

Database config url:
--------------------
```conf
postgresql://username:password@localhost:port/database?prefix=tableprefix&charset=utf-8
```

Sample code:
--------------------
```D
import entity;
    
import std.algorithm;
import std.stdio;

// Annotations of entity classes

class User {
    long id;
    string name;
    
    @ManyToMany
    LazyCollection!Role roles;
}

class Role {
    int id;
    string name;
    
    @ManyToMany
    LazyCollection!User users;
}

int main()
{
    // create metadata from annotations
    EntityMetaData schema = new SchemaInfoImpl!(User, Role);
    
    // setup DB connection factory
    version (USE_MYSQL) {
            MySQLDriver driver = new MySQLDriver();
            string url = MySQLDriver.generateUrl("localhost", 3306, "test_db");
            string[string] params = MySQLDriver.setUserAndPassword("testuser", "testpasswd");
            Dialect dialect = new MySQLDialect();
        } else {
        import ddbc.all;
            SQLITEDriver driver = new SQLITEDriver();
            string url = "zzz.db"; // file with DB
            static import std.file;
           
            string[string] params;
            Dialect dialect = new SQLiteDialect();
        }
        
        DataSource ds = new ConnectionPoolDataSourceImpl(driver, url, params);
        
        // create managerion factory
        EntityManagerFactory factory = new EntityManagerFactoryImpl(schema, dialect, ds);

        // Create schema if necessary
        {
            // get connection
            Connection conn = ds.getConnection();

            factory.getDBMetaData().updateDBSchema(conn, false, true);
        }

        // create managerion
        EntityManager manager = factory.createEntityManager();

        Role myrole = new Role();
        myrole.name = "Admin";
        
        User user = new User();
        user.name = "Brian";
        user.roles = myrole;
        
        manager.persist(myrole);
        manager.persist(user);
        
        manager.close();
        
        manager = factory.createEntityManager();

        writeln("user.name,", user.name);
        writeln("user.id,", user.id);

        User myuser = manager.createQuery("FROM User WHERE name=:username").
        setParameter("username", "Brian").uniqueResult!User();
    
        writeln("myuser.name,", myuser.name);
        writeln("myuser.id,", myuser.id);

        
        return 0;
    }
```
