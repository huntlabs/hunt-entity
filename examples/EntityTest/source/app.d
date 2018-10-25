import std.stdio;

import hunt.entity;
import Model.UserInfo;
import Model.UserApp;
import Model.AppInfo;
import Model.Car;
import Model.IDCard;
import Model.LoginInfo;

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

void  test_OneToOne(EntityManager em) {
	mixin(DO_TEST);
	
    auto uinfo = em.find!(UserInfo)(1);
	logDebug("Uinfo.IDCard is Lazy load : %s ".format(uinfo.card));
	auto card = uinfo.getCard;
	logDebug("Card( %s , %s ) ".format(card.id,card.desc));

	auto card2 = em.find!(IDCard)(1);
	logDebug("Uinfo( %s , %s ) ".format(card2.user.id,card2.user.nickName));
}

void  test_OneToMany(EntityManager em) {
	mixin(DO_TEST);
	
    auto uinfo = em.find!(UserInfo)(1);
	auto cars = uinfo.getCars();
	foreach(car;cars)
	{
		logDebug("Car( %s , %s ) ".format(car.id,car.name));
	}
}

void  test_ManyToOne(EntityManager em) {
	mixin(DO_TEST);
	
	auto car = em.find!(Car)(2);
	logDebug("Uinfo( %s , %s , %s ) ".format(car.user.id,car.user.nickName,car.user.age));
}

void  test_ManyToMany(EntityManager em) {
	mixin(DO_TEST);

    auto app = em.find!(AppInfo)(1);
	auto uinfos = app.getUinfos();
	logDebug("AppInfo( %s , %s , %s ) ".format(app.id,app.name,app.desc));
	foreach(uinfo ; uinfos)
		logDebug("AppInfo.UserInfo( %s , %s , %s ) ".format(uinfo.id,uinfo.nickName,uinfo.age));

	auto uinfo = em.find!(UserInfo)(1);
	auto apps = uinfo.getApps();
	logDebug("UserInfo( %s , %s , %s) ".format(uinfo.id,uinfo.nickName, uinfo.age));
	foreach(app2 ; apps)
		logDebug("UserInfo.AppInfo( %s , %s , %s ) ".format(app2.id,app2.name,app2.desc));
}



void test_eql_select(EntityManager em)
{
	mixin(DO_TEST);
	/// select statement
	auto query1 = em.createQuery!(UserInfo)(" select a from UserInfo a ;");
	foreach(d ; query1.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id,d.nickName,d.age));
	}

	auto query2 = em.createQuery!(LoginInfo)(" select a,b  from LoginInfo a left join a.uinfo b ;");
	foreach(d ; query2.getResultList())
	{
		logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,d.uinfo.nickName,d.uinfo.age));
		logDebug("LoginInfo( %s , %s , %s ) ".format(d.id,d.create_time,d.update_time));
	}

	auto query3 = em.createQuery!(LoginInfo)(" select b  from LoginInfo a left join a.uinfo b ;");
	foreach(d ; query3.getResultList())
	{
		logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,d.uinfo.nickName,d.uinfo.age));

	}

	auto query4 = em.createQuery!(LoginInfo)(" select a.id, a.create_time ,b.nickName  from LoginInfo a left join a.uinfo b where a.id in (?,?) order by a.id desc limit 0 ,1 ;");
	query4.setParameter(1,2);
	query4.setParameter(2,1);
	foreach(d ; query4.getResultList())
	{
		logDebug("Mixed Results( %s , %s , %s ) ".format(d.id,d.create_time,d.uinfo.nickName));
	}

	auto query5 = em.createQuery!(LoginInfo)(" select a, b ,c from LoginInfo a left join a.uinfo b  join a.app c where a.id = ? order by a.id desc;");
	query5.setParameter(1,2);
	foreach(d ; query5.getResultList())
	{
		logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,d.uinfo.nickName,d.uinfo.age));
		logDebug("LoginInfo.AppInfo( %s , %s , %s ) ".format(d.app.id,d.app.name,d.app.desc));
		logDebug("LoginInfo( %s , %s , %s ) ".format(d.id,d.create_time,d.update_time));
	}

	auto query6 = em.createQuery!(UserInfo,AppInfo)(" select a , b from UserInfo a left join AppInfo b on a.id = b.id ;");
	foreach(d ; query6.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id,d.nickName,d.age));
	}

	auto query7 = em.createQuery!(UserInfo)(" select a.nickName as name ,count(*) as num from UserInfo a group by a.nickName;");
	logDebug("UserInfo( %s ) ".format(query7.getNativeResult()));
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
    CriteriaBuilder builder = em.getCriteriaBuilder();

	test_OneToOne(em);

	test_OneToMany(em);

	test_ManyToOne(em);

	test_ManyToMany(em);

	test_eql_select(em);
}
