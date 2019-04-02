import std.stdio;

import hunt.entity;
import model.UserInfo;
import model.LoginInfo;
import model.AppInfo;


import hunt.logging;
import std.traits;
import std.format;
import std.array;
import core.stdc.stdlib;
import core.runtime;
import std.conv;

enum DO_TEST = `
    logInfo("BEGIN ----------------" ~ __FUNCTION__ ~ "--------------------");
    scope(success) logInfo("END   ----------------" ~ __FUNCTION__ ~ "----------OK----------");
    scope(failure) logError("END   ----------------" ~ __FUNCTION__ ~ "----------FAIL----------");`;

class TmpResult
{
	UInfo user;
	AppInfo app;
}

void test_select(EntityManager em)
{
	mixin(DO_TEST);
	/// select statement
	auto query1 = em.createQuery!(UInfo)(" select a from UInfo a ;");
	foreach(d ; query1.getResultList())
	{
		logDebug("UInfo( %s , %s , %s ) ".format(d.id,d.nickName,d.age));
	}

	auto query2 = em.createQuery!(LoginInfo)(" select a,b  from LoginInfo a left join a.uinfo b ;");
	foreach(d ; query2.getResultList())
	{
		logDebug("LoginInfo.UInfo( %s , %s , %s ) ".format(d.uinfo.id,d.uinfo.nickName,d.uinfo.age));
		logDebug("LoginInfo( %s , %s , %s ) ".format(d.id,d.create_time,d.update_time));
	}

	auto query3 = em.createQuery!(LoginInfo)(" select b  from LoginInfo a left join a.uinfo b ;");
	auto query3_1 = em.createQuery!(LoginInfo)(" select b  from LoginInfo a left join a.uinfo b ;");
	foreach(d ; query3_1.getResultList())
	{
		logDebug("LoginInfo.UInfo( %s , %s , %s ) ".format(d.uinfo.id,d.uinfo.nickName,d.uinfo.age));

	}

	auto query4 = em.createQuery!(LoginInfo)(" select a.id, a.create_time ,b.nickName  from LoginInfo a left join a.uinfo b where a.id in (:1,:2) order by a.id desc limit 0 ,1 ;");
	query4.setParameter("1",2);
	query4.setParameter("2",1);
	foreach(d ; query4.getResultList())
	{
		logDebug("Mixed Results( %s , %s , %s ) ".format(d.id,d.create_time,d.uinfo.nickName));
	}

	auto query5 = em.createQuery!(LoginInfo)(" select a, b ,c from LoginInfo a left join a.uinfo b  join a.app c where a.id = ? order by a.id desc;");
	query5.setParameter(1,2);
	foreach(d ; query5.getResultList())
	{
		logDebug("LoginInfo.UInfo( %s , %s , %s ) ".format(d.uinfo.id,d.uinfo.nickName,d.uinfo.age));
		logDebug("LoginInfo.AppInfo( %s , %s , %s ) ".format(d.app.id,d.app.name,d.app.desc));
		logDebug("LoginInfo( %s , %s , %s ) ".format(d.id,d.create_time,d.update_time));
	}

	auto query6 = em.createQuery!(UInfo,AppInfo)(" select a , b from UInfo a left join AppInfo b on a.id = b.id ;");
	foreach(d ; query6.getResultList())
	{
		logDebug("UInfo( %s , %s , %s ) ".format(d.id,d.nickName,d.age));
	}

	auto query7 = em.createQuery!(UInfo)(" select a.nickName as name ,count(*) as num from UInfo a group by a.nickName;");
	logDebug("UInfo( %s ) ".format(query7.getNativeResult()));
}


void test_update(EntityManager em)
{
	mixin(DO_TEST);
	/// update statement
	auto update = em.createQuery!(UInfo)(" update UInfo u set u.age = u.id, u.nickName = 'dd' where  u.age > 2 and u.age < :age2 and u.id = :id and u.nickName = :name " ); // update UInfo u set u.age = 5 where u.id = 2
	update.setParameter("age",2);
	update.setParameter("age2",55);
	update.setParameter("id",1);
	update.setParameter("name","tom");
	logDebug(" update result : ",update.exec());
}


void test_delete(EntityManager em)
{
	mixin(DO_TEST);
	/// delete statement
	auto del = em.createQuery!(UInfo)(" delete from UInfo u where u.id = ? "); 
	del.setParameter(1,3);
	logDebug(" del result : ",del.exec());
}

void test_insert(EntityManager em)
{
	mixin(DO_TEST);
	/// insert statement
	auto insert = em.createQuery!(UInfo)("  INSERT INTO UInfo u(u.nickName,u.age) values (:name,:age)"); 
	insert.setParameter("name","momomo");
	insert.setParameter("age",666);
	logDebug(" insert result : ",insert.exec());
}

void test_insert2(EntityManager em)
{
	mixin(DO_TEST);
	/// insert statement
	auto insert = em.createQuery!(UInfo)("  INSERT INTO UInfo u(u.nickName,u.age) values (?,?)"); 
	insert.setParameter(1,"Jons");
	insert.setParameter(2,2355);
	logDebug(" insert result : ",insert.exec());
}

void main()
{
	writeln("Edit source/app.d to start your project.");

	EntityOption option = new EntityOption();
    option.database.driver = "mysql";
    option.database.host = "10.1.11.171";
    option.database.port = 3306;
    option.database.database = "eql_test";
    option.database.username = "root";
    option.database.password = "123456";
    
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("db", option);
    EntityManager em = entityManagerFactory.createEntityManager();

	// test_select(em);

	// test_update(em);

	test_delete(em);

	test_insert(em);
	test_insert2(em);
	
}
