import std.stdio;

import hunt.entity;
import Model.UserInfo;
import Model.UserApp;
import Model.AppInfo;
import Model.Car;
import Model.IDCard;

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
	uinfo.setManager(em);
	logDebug("uinfo.IDCard : %s ".format(uinfo.card));
	auto card = uinfo.getCard;
	logDebug("Card( %s , %s ) ".format(card.id,card.desc));

	auto card2 = em.find!(IDCard)(1);
	card2.setManager(em);
	logDebug("card.user : %s ".format(card2.user));
	auto uinfo2 = card2.user;
	logDebug("Uinfo( %s , %s ) ".format(uinfo2.id,uinfo2.nickName));
}

void  test_OneToMany(EntityManager em) {
	mixin(DO_TEST);
	
    auto uinfo = em.find!(UserInfo)(1);
	uinfo.setManager(em);
	// logDebug("uinfo.cars : %s ".format(uinfo.cars));
	auto cars = uinfo.getCars();
	foreach(car;cars)
	{
		logDebug("Car( %s , %s ) ".format(car.id,car.name));
	}
}

void  test_ManyToOne(EntityManager em) {
	mixin(DO_TEST);
	
	auto car = em.find!(Car)(2);
	car.setManager(em);
	logDebug("card.user : %s ".format(car.user));
	auto uinfo2 = car.user;
	logDebug("Uinfo( %s , %s ) ".format(uinfo2.id,uinfo2.nickName));
}

void  test_ManyToMany(EntityManager em) {
	mixin(DO_TEST);

    auto app = em.find!(AppInfo)(1);
	app.setManager(em);
	auto uinfos = app.getUinfos();
	logDebug("AppInfo( %s , %s , %s ) ".format(app.id,app.name,app.desc));
	foreach(uinfo ; uinfos)
		logDebug("AppInfo.UserInfo( %s , %s ) ".format(uinfo.nickName,uinfo.age));

	auto uinfo = em.find!(UserInfo)(1);
	uinfo.setManager(em);
	auto apps = uinfo.getApps();
	logDebug("UserInfo( %s , %s) ".format(uinfo.nickName, uinfo.age));
	foreach(app2 ; apps)
		logDebug("UserInfo.AppInfo( %s , %s , %s ) ".format(app2.id,app2.name,app2.desc));
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

}
