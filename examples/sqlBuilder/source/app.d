import std.stdio;

import entity;

void main()
{
	writeln("Edit source/app.d to start your project.");
	DatabaseConfig config = new DatabaseConfig("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
	config.setMaximumConnection = 1;
	EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql",config);

	QueryBuilder builder;

	//create SQL Query Builder
	builder = entityManagerFactory.createQueryBuilder();

	//builder a Query
    int id = 2680;
    float money = 15.9;
    bool status = true;
    string name = "test";
	builder.select("id","name")
		.from("users")
        .where!int("id",CompareType.eq,id)
        .where!float("money",CompareType.eq,money)
        .where!bool("status",CompareType.eq,status)
        .where!string("name",CompareType.eq,name)
		.where("id = ?")
		.setParameter(0,"26680");
	writeln(builder);


	//insert 
	builder = entityManagerFactory.createQueryBuilder();
	builder.insert("users")
		.values([
			"id" : "?",
			"name" : "?",
			])
		.setValue("phone","?")
		.setParameter(0,"26681")
		.setParameter(1,"\"viile\"")
		.setParameter(2,"18812341234");
	writeln(builder);

	//delete
	builder = entityManagerFactory.createQueryBuilder();
	builder.remove("users")
		.where("id = ?")
		.where("name = ?")
		.setParameter(0,"26681")
		.setParameter(1,"\"viile\"")
		.orderBy("name","ASC")
		.limit(10);
	writeln(builder);

	//update
	builder = entityManagerFactory.createQueryBuilder();
	builder.update("users")
		.set("name","?")
		.setParameter(0,"\"viile\"")
		.where("id = 26681")
		.orderBy("name","ASC")
		.limit(10);
	writeln(builder);

	//Building Where Expressions 
	builder = entityManagerFactory.createQueryBuilder();
	builder.select("id", "name")
		.from("users")
		.where(
			builder.expr().andX(
				builder.expr().eq("username", "\"test\""),
				builder.expr().eq("email", "\"test@putao.com\""),
				builder.expr().orX(
					builder.expr().eq("role", "\"test\""),
					builder.expr().eq("public", "\"test@putao.com\""),
				)
			)
		);
	writeln(builder);
	
	//GROUP BY and HAVING Clause
	builder = entityManagerFactory.createQueryBuilder();
	builder.select("DATE(last_login) as date", "COUNT(id) AS users")
		.from("users")
		.groupBy("DATE(last_login)")
		.having("users > 10");
	writeln(builder);

	//Table alias
	builder = entityManagerFactory.createQueryBuilder();
	builder.select("id","name")
		.from("users","u")
		.where("id = ?")
		.setParameter(0,"26680");
	writeln(builder);

	//Join Clauses
	builder = entityManagerFactory.createQueryBuilder();
	builder.select("u.id","u.username","p.name")
		.from("users","u")
		.leftJoin("phone","p","p.uid = u.id")
		.where("u.id = ?")
		.setParameter(0,"26680");
	writeln(builder);

	//Limit Clause
	builder = entityManagerFactory.createQueryBuilder();
	builder.select("u.id","u.username","p.name")
		.from("users","u")
		.leftJoin("phone","p","p.uid = u.id")
		.where("u.id = ?")
		.setParameter(0,"26680")
		.setFirstResult(10)
		.setMaxResults(20);
	writeln(builder);
}

