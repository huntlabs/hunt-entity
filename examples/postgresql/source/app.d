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
import std.conv;
import hunt.database;

enum DO_TEST = `
    logInfo("BEGIN ----------------" ~ __FUNCTION__ ~ "--------------------");
    scope(success) logInfo("END   ----------------" ~ __FUNCTION__ ~ "----------OK----------");
    scope(failure) logError("END   ----------------" ~ __FUNCTION__ ~ "----------FAIL----------");`;

void test_persist(EntityManager em)
{
	mixin(DO_TEST);

	UserInfo user = new UserInfo();
	user.nickName = "Jame\"s Ha'Deng";
	user.age = 30;
	em.persist(user);
}

void test_merge(EntityManager em)
{
	mixin(DO_TEST);
	auto u = em.find!(UserInfo)(1);
	u.age = 100;
	em.merge!(UserInfo)(u);
}

void test_CriteriaQuery(EntityManager em)
{
	mixin(DO_TEST);

	CriteriaBuilder builder = em.getCriteriaBuilder();
	CriteriaQuery!UserInfo criteriaQuery = builder.createQuery!(UserInfo);
	Root!UserInfo root = criteriaQuery.from();
	string name = "tom";
	Predicate c1 = builder.equal(root.UserInfo.nickName, name);
	Predicate c2 = builder.gt(root.UserInfo.age, 0);
	criteriaQuery.orderBy(builder.asc(root.UserInfo.age), builder.asc(root.UserInfo.id));
	TypedQuery!UserInfo typedQuery = em.createQuery(criteriaQuery.select(root)
			.where(builder.or(c1, c2)));
	auto uinfos = typedQuery.getResultList();
	foreach (u; uinfos)
	{
		logDebug("Uinfo( %s , %s , %s ) ".format(u.id, u.nickName, u.age));
	}

}

void test_comparison(EntityManager em)
{
	mixin(DO_TEST);

	auto rep = new EntityRepository!(UserInfo, int)(em);
	string name = "Jame\"s Ha'Deng";
	auto uinfos = rep.findAll(new Expr().eq("nickName", name));
	foreach (u; uinfos)
	{
		logDebug("Uinfo( %s , %s , %s ) ".format(u.id, u.nickName, u.age));
	}
}

void test_delete(EntityManager em)
{
	mixin(DO_TEST);

	CriteriaBuilder builder = em.getCriteriaBuilder();
	CriteriaDelete!UserInfo criteriaDelete = builder.createCriteriaDelete!(UserInfo);
	Root!UserInfo root = criteriaDelete.from();
	string name = "Jame\"s Ha'Deng";
	Predicate c1 = builder.equal(root.UserInfo.nickName, name);
	Query!UserInfo query = em.createQuery(criteriaDelete.where(c1));
	auto res = query.executeUpdate();
	logDebug("exec delete : ", res);
}

void test_nativeQuery(EntityManager em)
{
	mixin(DO_TEST);

	auto nativeQuery = em.createNativeQuery(" select * from UserInfo;");
	logDebug("nativeQuery ResultSet : ", nativeQuery.getResultList());
}

void test_create_eql_by_queryBuilder(EntityManager em)
{
	mixin(DO_TEST);

	auto queryBuider = new QueryBuilder(em.getDatabase());
	queryBuider.from("UserInfo", "u");
	queryBuider.select("u");
	queryBuider.where(" u.id > :id").setParameter("id", 4);
	queryBuider.orderBy("u.id desc");

	assert("SELECT u\n" ~ 
			"FROM UserInfo u\n" ~ 
			"WHERE u.id > 4\n" ~ 
			"ORDER BY u.id DESC" == queryBuider.toString);
}

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

void test_eql_select(EntityManager em)
{
	mixin(DO_TEST);

	auto query1 = em.createQuery!(UserInfo)(" select a from UserInfo a ;");
	foreach (d; query1.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	}

	auto query2 = em.createQuery!(LoginInfo)(
			" select a,b  from LoginInfo a left join a.uinfo b ;");
	foreach (d; query2.getResultList())
	{
		logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
				d.uinfo.nickName, d.uinfo.age));
		logDebug("LoginInfo( %s , %s , %s ) ".format(d.id, d.create_time, d.update_time));
	}

	auto query3 = em.createQuery!(LoginInfo)(" select b  from LoginInfo a left join a.uinfo b ;");
	foreach (d; query3.getResultList())
	{
		logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
				d.uinfo.nickName, d.uinfo.age));

	}

	auto query4 = em.createQuery!(LoginInfo)(" select a.id, a.create_time ,b.nickName  from LoginInfo a left join a.uinfo b where a.id in (? , ? ) order by a.id desc LIMIT 1 OFFSET 1 ;");
	query4.setParameter(1, 2).setParameter(2, 1);
	foreach (d; query4.getResultList())
	{
		logDebug("Mixed Results( %s , %s , %s ) ".format(d.id, d.create_time, d.uinfo.nickName));
	}

	auto query5 = em.createQuery!(LoginInfo)(
			" select a, b ,c from LoginInfo a left join a.uinfo b  join a.app c where a.id = 2 order by a.id desc;");
	query5.setParameter(1, 2);
	foreach (d; query5.getResultList())
	{
		logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
				d.uinfo.nickName, d.uinfo.age));
		logDebug("LoginInfo.AppInfo( %s , %s , %s ) ".format(d.app.id, d.app.name, d.app.desc));
		logDebug("LoginInfo( %s , %s , %s ) ".format(d.id, d.create_time, d.update_time));
	}

	auto query6 = em.createQuery!(UserInfo,
			AppInfo)(" select a , b from UserInfo a left join AppInfo b on a.id = b.id ;");
	foreach (d; query6.getResultList())
	{
		logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
	}

	auto query7 = em.createQuery!(UserInfo)(
			" select a.nickName as name ,count(*) as num from UserInfo a group by a.nickName;");
	logDebug("UserInfo( %s ) ".format(query7.getNativeResult()));

	auto query8 = em.createQuery!(IDCard)(
			" select distinct b from IDCard a join a.user b where b.id = 2;");
	foreach (d; query8.getResultList())
	{
		logDebug("IDCard.UserInfo( %s , %s , %s ) ".format(d.user.id, d.user.nickName, d.user.age));
	}
}

void test_statement(EntityManager em)
{
	mixin(DO_TEST);

	auto db =em.getDatabase();
	Statement statement = db.prepare(`INSERT INTO users ( age , email, first_name, last_name) VALUES ( :age, :email, :firstName, :lastName )`);
	statement.setParameter(`age`, 16);
	statement.setParameter(`email`, "me@example.com");
	statement.setParameter(`firstName`, "John");
	statement.setParameter(`lastName`, "Doe");
	assert("INSERT INTO users ( age , email, first_name, last_name) VALUES ( 16, 'me@example.com', 'John', 'Doe' )" == statement.sql);
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

	auto query = em.createQuery!(UserInfo)(
			" select count(UserInfo.id) as num from UserInfo a ");
	logDebug("UserInfo( %s ) ".format(query.getNativeResult()));
}

void main()
{
	writeln("Edit source/app.d to start your project.");

	EntityOption option = new EntityOption();
	option.database.driver = "postgresql";
	option.database.host = "10.1.11.34";
	option.database.port = 5432;
	option.database.database = "exampledb";
	option.database.username = "postgres";
	option.database.password = "123456";

	EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("postgresql",
			option);
	EntityManager em = entityManagerFactory.createEntityManager();
	CriteriaBuilder builder = em.getCriteriaBuilder();

	test_OneToOne(em);

	test_OneToMany(em);

	test_ManyToOne(em);

	test_ManyToMany(em);

	test_eql_select(em);

	test_merge(em);

	test_persist(em);

	test_comparison(em);

	test_delete(em);

	test_CriteriaQuery(em);

	test_nativeQuery(em);

	test_create_eql_by_queryBuilder(em);

	test_statement(em);

	test_pagination(em);

	test_pagination_1(em);

}
