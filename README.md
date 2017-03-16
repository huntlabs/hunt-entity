HibernateD
==========

[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/buggins/hibernated?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

[![Build Status](https://travis-ci.org/buggins/hibernated.svg?branch=master)](https://travis-ci.org/buggins/hibernated)

HibernateD is ORM for D language (similar to Hibernate)

Project home page: https://github.com/buggins/hibernated
Documentation: https://github.com/buggins/hibernated/wiki

Uses DDBC as DB abstraction layer: https://github.com/buggins/ddbc

Available as DUB package

Use SQLite 3.7.11 or later. In older versions syntax INSERT INTO (col1, col2) VALUES (1, 2), (3, 4) is not supported.

Sample code:
--------------------

        import hibernated.core;
    import std.algorithm;
    import std.stdio;


// Annotations of entity classes

class User {
    long id;
    string name;
    Customer customer;
    @ManyToMany // cannot be inferred, requires annotation
    LazyCollection!Role roles;
}

class Customer {
    int id;
    string name;
    // Embedded is inferred from type of Address
    Address address;
    
    Lazy!AccountType accountType; // ManyToOne inferred
    
    User[] users; // OneToMany inferred
    
    this() {
        address = new Address();
    }
}

@Embeddable
class Address {
    string zip;
    string city;
    string streetAddress;
}

class AccountType {
    int id;
    string name;
}

class Role {
    int id;
    string name;
    @ManyToMany // w/o this annotation will be OneToMany by convention
    LazyCollection!User users;
}

int main() {
    
    // create metadata from annotations
    EntityMetaData schema = new SchemaInfoImpl!(User, Customer, AccountType, 
        Address, Role);
    
    
    
    
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
        

        // create session factory
        EntityManagerFactory factory = new EntityManagerFactoryImpl(schema, dialect, ds);
        scope(exit) factory.close();

        // Create schema if necessary
        {
        // get connection
        Connection conn = ds.getConnection();
        scope(exit) conn.close();
        // create tables if not exist
        factory.getDBMetaData().updateDBSchema(conn, false, true);
        }

        // Now you can use HibernateD

        // create session
        EntityManager sess = factory.createEntityManager();
        scope(exit) sess.close();

        // use session to access DB

        // read all users using query
        Query q = sess.createQuery("FROM User ORDER BY name");
        User[] list = q.list!User();

        // create sample data
        Role r10 = new Role();
        r10.name = "role10";
        Role r11 = new Role();
        r11.name = "role11";
        Customer c10 = new Customer();
        c10.name = "Customer 10";
        c10.address = new Address();
        c10.address.zip = "12345";
        c10.address.city = "New York";
        c10.address.streetAddress = "Baker st., 12";
        User u10 = new User();
        u10.name = "Alex";
        u10.customer = c10;
        u10.roles = [r10, r11];
        sess.save(r10);
        sess.save(r11);
        sess.save(c10);
        sess.save(u10);
        sess.close();
        sess = factory.createEntityManager();

        // load and check data
        User u11 = sess.createQuery("FROM User WHERE name=:Name").
                                   setParameter("Name", "Alex").uniqueResult!User();

        writeln("u11.customer.users.length=", u11.customer.users.length);
    writeln("u11.name,", u11.name);
    writeln("u11.id,", u11.id);

        //sess.update(u11);

        // remove entity
       // sess.remove(u11);

    User u112 = sess.createQuery("FROM User WHERE name=:Name").
        setParameter("Name", "Alex").uniqueResult!User();
    
    writeln("u11.customer.users.length=", u112.customer.users.length);
    writeln("u11.name,", u112.name);
    writeln("u11.id,", u112.id);

        
        return 0;
    }
