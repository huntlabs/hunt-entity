import std.stdio;

import hunt.entity;
import model.UserInfo;
import model.UserApp;
import model.AppInfo;
import model.Car;
import model.IDCard;
import model.LoginInfo;

import hunt.logging;
import std.traits;
import std.format;
import std.array;
import core.stdc.stdlib;
import core.runtime;
import core.thread;
import std.conv;
import hunt.database;

enum DO_TEST = `
    logInfo("BEGIN ----------------" ~ __FUNCTION__ ~ "--------------------");
    scope(success) logInfo("END   ----------------" ~ __FUNCTION__ ~ "----------OK----------");
    scope(failure) logError("END   ----------------" ~ __FUNCTION__ ~ "----------FAIL----------");`;


EntityOption getMysqlOptions() {

	EntityOption option = new EntityOption();
	option.database.driver = "mysql";
	option.database.host = "10.1.11.171";
	option.database.port = 3306;
	option.database.database = "eql_test";
	option.database.username = "root";
	option.database.password = "123456";
	option.database.prefix = "";

	return option;
}


EntityOption getPgOptions() {

	EntityOption option = new EntityOption();
	option.database.driver = "postgresql";
	option.database.host = "10.1.11.34";
	option.database.port = 5432;
	option.database.database = "exampledb";
	option.database.username = "postgres";
	option.database.password = "123456";	

	return option;
}


void main()
{

	EntityOption option = getMysqlOptions();
	// EntityOption option = getPgOptions();

	EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory(option);
	EntityManager em = entityManagerFactory.createEntityManager();

	scope(exit) {
		em.close();
	}
	// test_eql_select(em);
	// test_eql_select_with_reserved_word(em);
	// test_eql_update_with_reserved_word(em);

	// test_OneToOne(em);
	// test_OneToMany(em);
	// test_ManyToOne(em);
	// test_ManyToMany(em);
	// test_merge(em);
	// test_persist(em);
	// test_comparison(em);
	// test_delete(em);
	// test_CriteriaQuery(em);
	// test_nativeQuery(em);
	// test_create_eql_by_queryBuilder(em);
	// test_statement(em);
	// test_valid(em);
	// test_pagination(em);
	// test_pagination_1(em);
	// test_count(em);
	// test_transaction(em);
	// test_other(em);
	// test_exception(em);

	// test_EntityRepository_Count(em);
	// test_EntityRepository_Insert(em);
	// test_EntityRepository_Save(em);
	test_EntityRepository_Save_with_reserved_word(em);

	getchar();
}


/* ------------------------------------------------------------------------------------------------------------------ */
/*                                                      EQL tests                                                     */
/* ------------------------------------------------------------------------------------------------------------------ */

// void test_persist(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	UserInfo user = new UserInfo();
// 	user.nickName = "Jame\"s Ha'Deng";
// 	user.age = 30;
// 	em.persist(user);
// }

// void test_merge(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	auto u = em.find!(UserInfo)(1);
// 	u.age = 100;
// 	em.merge!(UserInfo)(u);
// }

// void test_CriteriaQuery(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	CriteriaBuilder builder = em.getCriteriaBuilder();
// 	CriteriaQuery!UserInfo criteriaQuery = builder.createQuery!(UserInfo);
// 	Root!UserInfo root = criteriaQuery.from();
// 	string name = "tom";
// 	Predicate c1 = builder.equal(root.UserInfo.nickName, name);
// 	Predicate c2 = builder.gt(root.UserInfo.age, 0);
// 	criteriaQuery.orderBy(builder.asc(root.UserInfo.age), builder.asc(root.UserInfo.id));
// 	TypedQuery!UserInfo typedQuery = em.createQuery(criteriaQuery.select(root)
// 			.where(builder.or(c1, c2)));
// 	auto uinfos = typedQuery.getResultList();
// 	foreach (u; uinfos)
// 	{
// 		logDebug("Uinfo( %s , %s , %s ) ".format(u.id, u.nickName, u.age));
// 	}

// }

// void test_comparison(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	auto rep = new EntityRepository!(UserInfo, int)(em);
// 	string name = "Jame\"s Ha'Deng";
// 	auto uinfos = rep.findAll(new Expr().eq("nickName", name));
// 	foreach (u; uinfos)
// 	{
// 		logDebug("Uinfo( %s , %s , %s ) ".format(u.id, u.nickName, u.age));
// 	}
// }

// void test_delete(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	CriteriaBuilder builder = em.getCriteriaBuilder();
// 	CriteriaDelete!UserInfo criteriaDelete = builder.createCriteriaDelete!(UserInfo);
// 	Root!UserInfo root = criteriaDelete.from();
// 	string name = "Jame\"s Ha'Deng";
// 	Predicate c1 = builder.equal(root.UserInfo.nickName, name);
// 	Query!UserInfo query = em.createQuery(criteriaDelete.where(c1));
// 	auto res = query.executeUpdate();
// 	logDebug("exec delete : ", res);
// }

// void test_nativeQuery(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	auto nativeQuery = em.createNativeQuery(" select * from UserInfo;");
// 	logDebug("nativeQuery ResultSet : ", nativeQuery.getResultList());
// }

// void test_create_eql_by_queryBuilder(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	auto queryBuider = new QueryBuilder(em.getDatabase());
// 	queryBuider.from("UserInfo", "u");
// 	queryBuider.select("u");
// 	queryBuider.where(" u.id > :id").setParameter("id", 4);
// 	queryBuider.orderBy("u.id desc");

// 	assert("SELECT u\n" ~ 
// 			"FROM UserInfo u\n" ~ 
// 			"WHERE u.id > 4\n" ~ 
// 			"ORDER BY u.id DESC" == queryBuider.toString);
// }

void test_OneToOne(EntityManager em)
{
	mixin(DO_TEST);

	auto uinfo = em.find!(UserInfo)(1);
	logDebug("Uinfo.IDCard is Lazy load : %s ".format(uinfo.card));
	auto card = uinfo.getCard;
	logDebug("Card( %s , %s ) ".format(card.id, card.desc));

	auto card2 = em.find!(IDCard)(1);
	logDebug("Uinfo( %s , %s ) ".format(card2.user.id, card2.user.nickName));
}

void test_OneToMany(EntityManager em)
{
	mixin(DO_TEST);

	auto uinfo = em.find!(UserInfo)(1);
	auto cars = uinfo.getCars();
	foreach (car; cars)
	{
		logDebug("Car( %s , %s ) ".format(car.id, car.name));
	}
}

void test_ManyToOne(EntityManager em)
{
	mixin(DO_TEST);

	auto car = em.find!(Car)(2);
	logDebug("Uinfo( %s , %s , %s ) ".format(car.user.id, car.user.nickName, car.user.age));
}

void test_ManyToMany(EntityManager em)
{
	mixin(DO_TEST);

	auto app = em.find!(AppInfo)(1);
	auto uinfos = app.getUinfos();
	logDebug("AppInfo( %s , %s , %s ) ".format(app.id, app.name, app.desc));
	foreach (uinfo; uinfos)
		logDebug("AppInfo.UserInfo( %s , %s , %s ) ".format(uinfo.id, uinfo.nickName, uinfo.age));

	auto uinfo = em.find!(UserInfo)(1);
	auto apps = uinfo.getApps();
	logDebug("UserInfo( %s , %s , %s) ".format(uinfo.id, uinfo.nickName, uinfo.age));
	foreach (app2; apps)
		logDebug("UserInfo.AppInfo( %s , %s , %s ) ".format(app2.id, app2.name, app2.desc));
}


void test_valid(EntityManager em)
{
	mixin(DO_TEST);

	auto query = em.createQuery!UserInfo("select u from UserInfo u where u.id = :id;");
	query.setParameter("id",3);
	auto uinfos = query.getResultList();
	foreach(u;uinfos)
		assert(u.valid.isValid);
}

void test_pagination(EntityManager em)
{
	mixin(DO_TEST);

	auto query = em.createQuery!(UserInfo)(" select a from UserInfo a where a.age > :age order by a.id ",new Pageable(0,2)).setParameter("age",10);
	auto page = query.getPageResult();
	logDebug("UserInfo -- Page(PageNo : %s ,size of Page : %s ,Total Pages: %s,Total : %s)".format(page.getNumber(),page.getSize(),page.getTotalPages(),page.getTotalElements()));
	foreach(d ; page.getContent())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	}
}

void test_pagination_1(EntityManager em)
{
	mixin(DO_TEST);

	auto query = em.createQuery!(UserInfo)(" select a from UserInfo a ").setFirstResult(1).setMaxResults(2);
	foreach (d; query.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	}
}

void test_count(EntityManager em)
{
	mixin(DO_TEST);

	// FIXME: Needing refactor or cleanup -@zhangxueping at 2019-10-09T15:23:59+08:00
	// Give some warning message.
	string sql = " select count(UserInfo.id) as num from UserInfo a "; // bug
	// sql = " select count(a.id) as num from UserInfo a "; 
	sql = " select count(*) as num from UserInfo a "; 

	auto query = em.createQuery!(UserInfo)(sql);
	logDebug("UserInfo( %s ) ".format(query.getNativeResult()));
	RowSet rs = query.getNativeResult();
	assert(rs.size() > 0);
	Row row = rs.iterator.front();
	long count = row.getLong(0);
	infof("count: %d", count);
}

void test_transaction(EntityManager em)
{
	mixin(DO_TEST);
	em.getTransaction().begin();
	auto update = em.createQuery!(UserInfo)(" update UserInfo u set u.age = :age where u.id = :id ").setParameter("age",77).setParameter("id",4);

	logDebug(" update result : ",update.exec());
	em.getTransaction().commit();

	em.getTransaction().begin();
	auto update1 = em.createQuery!(UserInfo)(" update UserInfo u set u.age = :age where u.id = :id ").setParameter("age",88).setParameter("id",4);

	logDebug(" update1 result : ",update1.exec());
	em.getTransaction().rollback();
}

void test_connect(EntityManager em)
{
	mixin(DO_TEST);

	auto group = new ThreadGroup();
	// logDebug("init Database pool size : ",em.getDatabase().getPoolSize());
    foreach (_; 0 .. 20)
    {
        group.create(() { 
                auto nativeQuery = em.createNativeQuery(" select * from UserInfo;");
				nativeQuery.getResultList();
            });
    }
	// logDebug("Database pool size : ",em.getDatabase().getPoolSize());
    group.joinAll();
	
}


void test_other(EntityManager em)
{
	mixin(DO_TEST);
	auto query1 = em.createQuery!(UserInfo)(" select a from UserInfo a order by field(a.id,1,2);");
	foreach (d; query1.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	}
}

void test_exception(EntityManager em)
{
	mixin(DO_TEST);
	auto query1 = em.createQuery!(UserInfo)(" select sum(a.id) as id from UserInfo a ");
	foreach (d; query1.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	}
}

void test_eql_select(EntityManager em)
{
	mixin(DO_TEST);
	/// select statement


// SELECT Car.uid AS Car__as__uid, Car.id AS Car__as__id, Car.name AS Car__as__name
// FROM Car 
// WHERE Car.id = 1
	auto query0 = em.createQuery!(Car)(" select a from Car a where a.id = 1;");
	foreach (Car d; query0.getResultList())
	{
		logDebug("Car( %s , %s , %s ) ".format(d.id, d.name, d.uid));
	}



	// auto query1 = em.createQuery!(UserInfo)(" select a from UserInfo a ;");
	// foreach (d; query1.getResultList())
	// {
	// 	logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	// }

	// auto query2 = em.createQuery!(LoginInfo)(
	// 		" select a,b  from LoginInfo a left join a.uinfo b ;");
	// foreach (d; query2.getResultList())
	// {
	// 	logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
	// 			d.uinfo.nickName, d.uinfo.age));
	// 	logDebug("LoginInfo( %s , %s , %s ) ".format(d.id, d.create_time, d.updated));
	// }

	// auto query3 = em.createQuery!(LoginInfo)(" select b  from LoginInfo a left join a.uinfo b ;");
	// foreach (d; query3.getResultList())
	// {
	// 	logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
	// 			d.uinfo.nickName, d.uinfo.age));

	// }

	// auto query4 = em.createQuery!(LoginInfo)(" select a.id, a.create_time ,b.nickName  from LoginInfo a left join a.uinfo b where a.id in (?,?) order by a.id desc limit 0 ,1 ;");
	// query4.setParameter(1, 2).setParameter(2, 1);
	// foreach (d; query4.getResultList())
	// {
	// 	logDebug("Mixed Results( %s , %s , %s ) ".format(d.id, d.create_time, d.uinfo.nickName));
	// }

	// auto query5 = em.createQuery!(LoginInfo)(
	// 		" select a, b ,c from LoginInfo a left join a.uinfo b  join a.app c where a.id = :id order by a.id desc;");
	// query5.setParameter("id", 2);
	// foreach (d; query5.getResultList())
	// {
	// 	logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
	// 			d.uinfo.nickName, d.uinfo.age));
	// 	logDebug("LoginInfo.AppInfo( %s , %s , %s ) ".format(d.app.id, d.app.name, d.app.desc));
	// 	logDebug("LoginInfo( %s , %s , %s ) ".format(d.id, d.create_time, d.updated));
	// }

// SELECT LoginInfo.location AS LoginInfo__as__location, LoginInfo.id AS LoginInfo__as__id, LoginInfo.uid AS LoginInfo__as__uid, LoginInfo.update_time AS LoginInfo__as__update_time, LoginInfo.create_time AS LoginInfo__as__create_time
//         , UserInfo.nickname AS UserInfo__as__nickname, UserInfo.age AS UserInfo__as__age, UserInfo.id AS UserInfo__as__id, AppInfo.desc AS AppInfo__as__desc, AppInfo.id AS AppInfo__as__id
//         , AppInfo.name AS AppInfo__as__name
// FROM LoginInfo 
//         LEFT JOIN UserInfo  ON LoginInfo.uid = UserInfo.id
//         JOIN AppInfo  ON LoginInfo.appid = AppInfo.id
// WHERE LoginInfo.id = 2	

	// auto query6 = em.createQuery!(UserInfo,
	// 		AppInfo)(" select a , b from UserInfo a left join AppInfo b on a.id = b.id ;");
	// foreach (d; query6.getResultList())
	// {
	// 	logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	// }

	// auto query7 = em.createQuery!(UserInfo)(
	// 		" select a.nickName as name ,count(*) as num from UserInfo a group by a.nickName;");
	// logDebug("UserInfo( %s ) ".format(query7.getNativeResult()));

	// auto query8 = em.createQuery!(IDCard)(
	// 		" select distinct b from IDCard a join a.user b where b.id = 2;");
	// foreach (d; query8.getResultList())
	// {
	// 	logDebug("IDCard.UserInfo( %s , %s , %s ) ".format(d.user.id, d.user.nickName, d.user.age));
	// }
}


void test_eql_select_with_reserved_word(EntityManager em)
{
	mixin(DO_TEST);
	// FIXME: Needing refactor or cleanup -@zhangxueping at 2019-10-08T10:21:38+08:00
	// DCD crashed AppInfo
	string sql = "select a from AppInfo a where a.id = 1;";
	// sql = "select a from AppInfo a where a.desc = 'it\'s a IM service';"; // bug  it's a IM service

	
	sql = "select a from AppInfo a where a.desc = 'service';"; 
// SELECT AppInfo.desc AS AppInfo__as__desc, AppInfo.id AS AppInfo__as__id, AppInfo.name AS AppInfo__as__name
// FROM AppInfo 
// WHERE AppInfo.`desc` = 'service'	
	auto query0 = em.createQuery!(AppInfo)(sql);
	foreach (AppInfo info; query0.getResultList())
	{
		logDebug("AppInfo( %s , %s , %s ) ".format(info.id, info.name, info.desc));
	}
}

void test_eql_update_with_reserved_word(EntityManager em)
{
	mixin(DO_TEST);
	string sql = "update AppInfo a set a.desc = 'test' where a.id = 1;";
	auto update = em.createQuery!(AppInfo)(sql);
	logDebug(" update result : ",update.exec());

	// UPDATE AppInfo 
	// SET AppInfo.desc = 'test'
	// WHERE AppInfo.id = 1
}

// void test_eql_update(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	/// update statement
// 	auto update = em.createQuery!(UInfo)(" update UInfo u set u.age = u.id, u.nickName = 'dd' where  " ~ 
// 		"u.age > 2 and u.age < :age2 and u.id = :id and u.nickName = :name " ); 
// 		// update UInfo u set u.age = 5 where u.id = 2

// 	update.setParameter("age",2);
// 	update.setParameter("age2",55);
// 	update.setParameter("id",1);
// 	update.setParameter("name","tom");
// 	logDebug(" update result : ",update.exec());
// }


// void test_eql_delete(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	/// delete statement
// 	auto del = em.createQuery!(UInfo)(" delete from UInfo u where u.id = 3 "); 
// 	// del.setParameter(1,3);
// 	logDebug(" del result : ",del.exec());
// }

// void test_eql_insert(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	/// insert statement
// 	auto insert = em.createQuery!(UInfo)("  INSERT INTO UInfo u(u.nickName,u.age) values (:name,:age)"); 
// 	insert.setParameter("name","momomo");
// 	insert.setParameter("age",666);
// 	logDebug(" insert result : ",insert.exec());
// }

// void test_eql_insert2(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	/// insert statement
// 	auto insert = em.createQuery!(UInfo)("  INSERT INTO UInfo u(u.nickName,u.age) values (?,?)"); 
// 	insert.setParameter(1,"Jons");
// 	insert.setParameter(2,2355);
// 	logDebug(" insert result : ",insert.exec());
// }

// void test_statement(EntityManager em)
// {
// 	mixin(DO_TEST);

// 	auto db =em.getDatabase();
// 	Statement statement = db.prepare(`INSERT INTO users ( age , email, first_name, last_name) VALUES ( :age, :email, :firstName, :lastName )`);
// 	statement.setParameter(`age`, 16);
// 	statement.setParameter(`email`, "me@example.com");
// 	statement.setParameter(`firstName`, "John");
// 	statement.setParameter(`lastName`, "Doe");
// 	logInfo("sql :",statement.sql);
// 	assert("INSERT INTO users ( age , email, first_name, last_name) VALUES ( 16, 'me@example.com', 'John', 'Doe' )" == statement.sql);
// }


void test_eql_ManyToOne(EntityManager em)
{
	mixin(DO_TEST);

	// Car car = em.find!(Car)(2);
	// logDebug("Uinfo( %s , %s , %s ) ".format(car.user.id, car.user.nickName, car.user.age));

	// car = em.createQuery!(Car)(("SELECT u,f FROM Car u LEFT JOIN UserInfo f ON f.id=u.uid;");

	// warning("Uinfo( %s , %s , %s ) ".format(car.user.id, car.user.nickName, car.user.age));
}


/* ------------------------------------------------------------------------------------------------------------------ */
/*                                               Entity Repository                                                    */
/* ------------------------------------------------------------------------------------------------------------------ */

void test_EntityRepository_Count(EntityManager em)
{
	mixin(DO_TEST);

	EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

	long count = rep.count();
	tracef("count: %d", count);
}


void test_EntityRepository_Insert(EntityManager em)
{
	mixin(DO_TEST);

	EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

	LoginInfo loginInfo = new LoginInfo();
	loginInfo.location = "new location";

	rep.insert(loginInfo);
}

void test_EntityRepository_Save(EntityManager em)
{
	mixin(DO_TEST);

	EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

	LoginInfo loginInfo = rep.findById(1);
	warning("LoginInfo(id: %d, uid: %d, updated: %d); Uinfo( %s) ".format(loginInfo.id, 
		loginInfo.uid, loginInfo.updated, loginInfo.uinfo));

	loginInfo.updated += 1;
	rep.save(loginInfo);
	LoginInfo newInfo = rep.findById(1);
	logDebug("Uinfo(id: %d, updated: %d, Uinfo( %s) ".format(newInfo.id, newInfo.updated, loginInfo.uinfo));
}


void test_EntityRepository_Save_with_reserved_word(EntityManager em)
{
	mixin(DO_TEST);

	EntityRepository!(AppInfo, int) rep = new EntityRepository!(AppInfo, int)(em);

	AppInfo info = rep.findById(1);
	infof("AppInfo(id: %d, desc: %s, available: %s) ".format(info.id, info.desc, info.isAvailable));

	// info.desc = "test1";
	// rep.save(info);
	// UPDATE AppInfo
	// SET desc = 'test1', name = 'Vitis'
	// WHERE AppInfo.id = 1	
	
	// info = rep.findById(1);
	// warning("AppInfo(id: %d, desc: %s) ".format(info.id, info.desc));
}
