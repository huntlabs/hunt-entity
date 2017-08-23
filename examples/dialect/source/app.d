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
    string status;

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

string display(User user)
{
    with(user) {
        JSONValue json;
        json["id"] = id;
        json["name"] = name;
        json["money"] = money;
        json["status"] = status;
        return json.toString;
    }
}

void main()
{
    writeln("Edit source/app.d to start your project.");
    DatabaseConfig config = new DatabaseConfig("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
    config.setMaximumConnection = 1;
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql",config);
    EntityManager entitymanager = entityManagerFactory.createEntityManager!(User,Blog);

    auto dialect = entitymanager.dialect;
    int test = 1; 
    writeln(dialect.toSqlValue!(int)(test));
}

