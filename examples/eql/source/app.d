import std.stdio;

import hunt.entity;
import Model.UserInfo;
import Model.LoginInfo;

import hunt.logging;
import std.traits;
import std.format;
import std.array;
import core.stdc.stdlib;
import core.runtime;
import std.conv;



class Result
{
	string nickname;
	int create_time;
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

    
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql", option);
    EntityManager em = entityManagerFactory.createEntityManager();

	auto query = em.createEqlQuery!(Result,UInfo,LoginInfo)(" select a.nickName as nickname , b.create_time from UInfo a left join LoginInfo b on a.id = b.uid where a.id in (1,2);");
	Result[] results = query.getResultList();
	foreach(d ; results)
	{
		logDebug("( %s , %s ) ".format(d.nickname,d.create_time));
	}

	auto update = em.createEqlQuery!(UInfo)(" update UInfo u set u.age = ? where id = ? "); // update UInfo u set u.age = :1 where id = :2
	update.setParameter(2,2);
	update.setParameter(1,5);
	logDebug(" update result : ",update.executeUpdate());
	
	auto query1 = em.createEqlQuery!(LoginInfo)(" select a.*  from LoginInfo a ;");
	LoginInfo[] infos = query1.getResultList();
	foreach(d ; infos)
	{
		logDebug("( %s , %s , %s ) ".format(d.uid,d.create_time,d.update_time));
	}

	auto query2 = em.createEqlQuery!(UInfo)(" select a.nickName as nickName , a.*  from UInfo a ;");
	foreach(d ; query2.getResultList())
	{
		logDebug("( %s , %s , %s ) ".format(d.id,d.nickName,d.age));
	}
}
