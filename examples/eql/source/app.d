import std.stdio;

import hunt.entity;
import Model.UserInfo;
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
	int AppId;
}

void main()
{
	writeln("Edit source/app.d to start your project.");

	EntityOption option = new EntityOption();
    option.database.driver = "mysql";
    option.database.host = "10.1.11.34";
    option.database.port = 3306;
    option.database.database = "pt_friend";
    option.database.username = "root";
    option.database.password = "123456";
    //can add table prefix "test_" means table name is "test_user";
    option.database.prefix = "";

    
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql", option);



    EntityManager em = entityManagerFactory.createEntityManager();

	auto query = em.createEqlQuery!(Result,UInfo,FrdRlt)(" select a.NickName as nickname , b.AppId from UInfo a left join FrdRlt b on a.UserId = b.MasterId where a.UserId = 6083472;");

	auto data = query.getResultList();
	foreach(d ; data)
		logDebug("query result : ",d.nickname);

	// auto update = em.createEqlQuery!(UInfo)(" update UInfo u set u.Avatar = 'www.qq.com' where id = 63 ");

	// logDebug(" update result : ",update.executeUpdate());
	
}
