import std.stdio;

import hunt.entity;
import model.UserInfo;
import model.UserApp;
import model.AppInfo;
import model.Car;
import model.IDCard;
import model.LoginInfo;
import model.Agent;
import model.AgentAsset;

import hunt.logging;
import std.traits;
import std.format;
import std.array;
import core.stdc.stdlib;
import core.runtime;
import core.thread;
import std.conv;
import hunt.database;


import hunt.serialization.JsonSerializer;
import hunt.serialization.Common;
import std.json;

void main()
{

    // EntityOption option = getMysqlOptions();
    // EntityOption option = getMysqlDevOptions(); // to test mysql 8
    EntityOption option = getPgOptions();
    // EntityOption option = getPgDevOptions();

    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory(option);
    EntityManager em = entityManagerFactory.currentEntityManager();

    scope(exit) {
        em.close();
        // warning("checking");
    }

    // test_eql_insert(em);
    test_eql_select(em);
    test_eql_select_with_join(em);
    // test_eql_select_with_reserved_word(em);
    // test_eql_update_with_reserved_word(em);

    // test_OneToOne(em);
    // test_OneToMany(em);
    // test_ManyToOne(em);
    // test_ManyToMany(em);
    // test_MixMapping1(em);
    // test_MixMapping2(em);


    // test_merge(em);
    // test_persist(em);
    // test_comparison(em);
    // test_delete(em);
    // test_CriteriaQuery(em);
    // test_nativeQuery(em);
    // test_create_eql_by_queryBuilder(em);
    // test_statement(em);
    // test_valid(em);
    // test_subquery(em);
    // test_pagination(em);
    // test_pagination_1(em);
    // test_count(em);
    // test_transaction(em);
    // test_other(em);
    // test_exception(em);

    // test_EntityRepository_Insert(em);
    // test_EntityRepository_Save(em);
    // test_EntityRepository_Save_with_reserved_word(em);
    // test_EntityRepository_Insert02(em);
    // test_EntityRepository_Count(em);
    // test_EntityRepository_Sum(em);
    // testRepositoryWithTransaction(em);
    // testRepositoryWithTransaction2(em);
    getchar();

    // testBinarySerializationForModel();
    // testJsonSerializationForModel();
}


/* ------------------------------------------------------------------------------------------------------------------ */
/*                                                      EQL tests                                                     */
/* ------------------------------------------------------------------------------------------------------------------ */

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
    auto uinfos = rep.findAll(new Expr().eq(rep.field().nickName, name));
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


    // {
    //     UserInfo uinfo = em.find!(UserInfo)(1);
    //     warningf("userInfo, id: %d, nickName: %s", uinfo.id, uinfo.nickName);
    //     // warningf("Uinfo.IDCard is loaded lazily: %s ".format(uinfo.card is null));

    //     IDCard idCard = uinfo.card; 

    //     if(idCard !is null ) {
    //         warningf("CardInfo, uid: %d, desc: %s, user: %s", idCard.uid, idCard.desc, idCard.user is null);

    //         UserInfo uinfo2 = idCard.user;
    //         assert(uinfo2 !is null && uinfo2.id > 0);
    //         assert(uinfo is uinfo2);

    //         if(uinfo2 !is null) {
    //             warningf("userInfo, id: %d, nickName: %s", uinfo2.id, uinfo2.nickName);
    //         }
    //     }
    // }

    // {
    //     IDCard idCardInfo = em.find!(IDCard)(1);
    //     warningf("CardInfo, id: %s, desc: %s", idCardInfo.id, idCardInfo.desc);

    //     UserInfo userInfo = idCardInfo.user;
    //     if(userInfo !is null ) {
    //         IDCard newCardInfo = userInfo.card;

    //         warningf("userInfo, id: %d, nickName: %s, card: %s", userInfo.id, userInfo.nickName, newCardInfo is null);

    //         if(idCardInfo !is null) {
    //             assert(newCardInfo !is null && newCardInfo.id > 0);
    //             assert(newCardInfo is idCardInfo);
    //             warningf("CardInfo, id: %s, desc: %s", newCardInfo.id, newCardInfo.desc);
    //         }
    //     } else {
    //         error("userInfo is null");
    //     }
    // }

    // {
    // 	UserInfo uinfo = em.find!(UserInfo)(1);
    // 	warningf("userInfo, id: %d, nickName: %s", uinfo.id, uinfo.nickName);
    // 	// warningf("Uinfo.IDCard is loaded lazily: %s ".format(uinfo.card is null));

    // 	Car car = uinfo.car; 

    // 	if(car !is null ) {
    // 		warningf("Car, uid: %d, name: %s", car.uid, car.name);
    // 	}
    // }

    // {
    // 	UserInfo uinfo = em.find!(UserInfo)(1);
    // 	warningf("userInfo, id: %d, nickName: %s", uinfo.id, uinfo.nickName);
    // 	// warningf("Uinfo.IDCard is loaded lazily: %s ".format(uinfo.card is null));

    // 	Car[] cars = uinfo.cars; 

    // 	if(cars !is null ) {
    // 		foreach(Car car; cars) {
    // 			warningf("Car, uid: %d, name: %s", car.uid, car.name);
    // 		}
    // 	}
    // }	
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

void test_MixMapping1(EntityManager em) {
    UserInfo uinfo = em.find!(UserInfo)(1);
    warningf("userInfo, id: %d, nickName: %s", uinfo.id, uinfo.nickName);

    // ID Card
    IDCard idCard = uinfo.card;
    assert(idCard !is null);
    warningf("CardInfo, uid: %d, desc: %s, user: %s", idCard.uid, idCard.desc, idCard.user is null);

    UserInfo uinfo2 = idCard.user;
    if (uinfo2 !is null) {
        warningf("userInfo, id: %d, nickName: %s", uinfo2.id, uinfo2.nickName);
    }

    // assert(uinfo2 is uinfo);

    // Cars
    // Car[] cars = uinfo.getCars();
    Car[] cars = uinfo.cars;
    assert(cars.length > 0);

    foreach (car; cars) {
        warningf("Car, uid: %d, name: %s", car.uid, car.name);
    }
}

void test_MixMapping2(EntityManager em) {

    IDCard idCardInfo = em.find!(IDCard)(1);
    warningf("CardInfo, id: %s, desc: %s", idCardInfo.id, idCardInfo.desc);

    UserInfo userInfo = idCardInfo.user;
    if(userInfo !is null ) {
        
        IDCard newCardInfo = userInfo.card;
        warningf("userInfo, id: %d, nickName: %s, card: %s", userInfo.id, userInfo.nickName, newCardInfo is null);
        
        Car[] cars = userInfo.cars;
        // cars = userInfo.getCars();
        assert(cars.length > 0);

        foreach (car; cars) {
            warningf("Car, uid: %d, name: %s", car.uid, car.name);
        }

    } else {
        error("userInfo is null");
    }    
}


// void test_ManyToMany(EntityManager em)
// {
//     mixin(DO_TEST);

//     auto app = em.find!(AppInfo)(1);
//     auto uinfos = app.getUinfos();
//     logDebug("AppInfo( %s , %s , %s ) ".format(app.id, app.name, app.desc));
//     foreach (uinfo; uinfos)
//         logDebug("AppInfo.UserInfo( %s , %s , %s ) ".format(uinfo.id, uinfo.nickName, uinfo.age));

//     auto uinfo = em.find!(UserInfo)(1);
//     auto apps = uinfo.getApps();
//     logDebug("UserInfo( %s , %s , %s) ".format(uinfo.id, uinfo.nickName, uinfo.age));
//     foreach (app2; apps)
//         logDebug("UserInfo.AppInfo( %s , %s , %s ) ".format(app2.id, app2.name, app2.desc));
// }


void test_valid(EntityManager em)
{
    mixin(DO_TEST);

    auto query = em.createQuery!UserInfo("select u from UserInfo u where u.id = :id;");
    query.setParameter("id",3);
    auto uinfos = query.getResultList();
    foreach(u;uinfos)
        assert(u.valid.isValid);
}

void test_subquery(EntityManager em) {
    string queryString = "select a from Car a where a.uid in (select b.id from UserInfo b where b.age = 5) ";
    // string queryString = "select a from Car a where a.uid in (1, 2) ";
    EqlQuery!(Car, UserInfo) query = em.createQuery!(Car, UserInfo)(queryString);

    Car[] cars = query.getResultList();

    warning(cars.length);

    foreach(Car car; cars) {
        warningf("Car, uid: %d, name: %s", car.uid, car.name);
    }
}


void test_pagination(EntityManager em)
{
    mixin(DO_TEST);

    // {
    //     EqlQuery!UserInfo query = em.createQuery!(UserInfo)(" select a from UserInfo a where a.age > :age order by a.id ",
    //             new Pageable(0,2)).setParameter("age",0);

    //     Page!UserInfo page = query.getPageResult();
    //     logDebug("UserInfo -- Page(PageNo : %s ,size of Page : %s ,Total Pages: %s,Total : %s)".format(page.getNumber(),
    //             page.getSize(),page.getTotalPages(), page.getTotalElements()));

    //     foreach(d ; page.getContent())
    //     {
    //         logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
    //     }
    // }

    {
        string queryString = "select a, b from UserInfo a left join AppInfo b on a.id = b.id " ~ 
            " where a.age > :age order by a.id ";
        EqlQuery!(UserInfo, AppInfo) query = em.createQuery!(UserInfo, AppInfo)(queryString, new Pageable(0,2))
            .setParameter("age",10);
            
        Page!UserInfo page = query.getPageResult();
        logDebug("UserInfo -- Page(PageNo : %s ,size of Page : %s ,Total Pages: %s,Total : %s)".format(page.getNumber(),
                page.getSize(),page.getTotalPages(),page.getTotalElements()));

        foreach(UserInfo d ; page.getContent())
        {
            IDCard card = d.getCard();
            if(card is null) {
                warning("No data for IDCard");
            }

            AppInfo[] apps = d.apps;
            trace(apps.length);
            foreach(AppInfo app; apps) {
                warning(app.name);
            }

            logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
        }
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
    // string sql = " select count(UserInfo.id) as num from UserInfo a "; // bug
    // sql = " select count(a.id) as num from UserInfo a "; 
    string sql = " select count(*) as num from UserInfo a where a.id < 5 "; 

    EqlQuery!UserInfo query = em.createQuery!(UserInfo)(sql);
    logDebug("UserInfo( %s ) ".format(query.getNativeResult()));
    RowSet rs = query.getNativeResult();
    assert(rs.size() > 0);
    Row row = rs.firstRow();
    long count = row.getLong(0);
    warningf("count: %d", count);
}

void test_transaction(EntityManager em)
{
    mixin(DO_TEST);
    em.getTransaction().begin();
    auto update = em.createQuery!(UserInfo)(" update UserInfo u set u.age = :age where u.id = :id ").setParameter("age",77).setParameter("id",4);

    logDebug(" update result : ",update.exec());
    em.getTransaction().commit();

    em.getTransaction().begin();
    EqlQuery!(UserInfo) update1 = em.createQuery!(UserInfo)(" update UserInfo u set u.age = :age where u.id = :id ").setParameter("age",88).setParameter("id",4);

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


    // case 1
// SELECT Car.uid AS Car__as__uid, Car.id AS Car__as__id, Car.name AS Car__as__name
// FROM Car 
// WHERE Car.id = 1
    // EqlQuery!(Car) query0 = em.createQuery!(Car)(" select a from Car a where a.id = 1;");
    // EqlQuery!(Car) query0 = em.createQuery!(Car)(" select a from Car a;");
    // // EqlQuery!(Car) query0 = em.createQuery!(Car)(" select a from Car a where a.name is null;");
    // // EqlQuery!(Car) query0 = em.createQuery!(Car)(" select a from Car a where a.name = '';");
    // Car[] results = query0.getResultList();
    // foreach (Car d; results)
    // {
    //     logDebug("Car( %s , %s , %s ) ".format(d.id, d.name, d.uid));
    //     infof("%s , %s", d.name is null, d.name == "");
    // }


    // case 2
    // EqlQuery!(UserInfo) query1 = em.createQuery!(UserInfo)(" select a from UserInfo a where a.id = 1;");
    // foreach (UserInfo uinfo; query1.getResultList())
    // {
    //     logDebug("UserInfo( %s , %s , %s ) ".format(uinfo.id, uinfo.nickName, uinfo.age));

    //     // IDCard idCard = uinfo.card; 
    //     IDCard idCard = uinfo.getCard(); 

    //     if(idCard !is null ) {
    //         warningf("CardInfo, uid: %d, desc: %s, user: %s", idCard.uid, idCard.desc, idCard.user is null);

    //         UserInfo uinfo2 = idCard.user;
    //         // assert(uinfo2 !is null && uinfo2.id > 0);
    //         // assert(uinfo is uinfo2);

    //         if(uinfo2 !is null) {
    //             warningf("userInfo, id: %d, nickName: %s", uinfo2.id, uinfo2.nickName);
    //         } else {
    //             warning("The uinfo is null");
    //         }
    //     } else {
    //         warning("The IDCard is null");
    //     }
    // }

    // case 3
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

{
	auto query5 = em.createQuery!(LoginInfo)(
			" select a, b ,c from LoginInfo a left join a.uinfo b  join a.app c where a.id = :id order by a.id desc;");    
    query5.setParameter("id", 2);
    foreach (d; query5.getResultList())
    {
    	logDebug("LoginInfo.UserInfo( %s , %s , %s ) ".format(d.uinfo.id,
    			d.uinfo.nickName, d.uinfo.age));
    	logDebug("LoginInfo.AppInfo( %s , %s , %s ) ".format(d.app.id, d.app.name, d.app.desc));
    	logDebug("LoginInfo( %s , %s , %s ) ".format(d.id, d.create_time, d.updated));
    }

// The generated sql:
// SELECT LoginInfo.location AS LoginInfo__as__location, LoginInfo.id AS LoginInfo__as__id, LoginInfo.uid AS LoginInfo__as__uid, LoginInfo.update_time AS LoginInfo__as__update_time, LoginInfo.create_time AS LoginInfo__as__create_time
//         , UserInfo.nickname AS UserInfo__as__nickname, UserInfo.age AS UserInfo__as__age, UserInfo.id AS UserInfo__as__id, AppInfo.desc AS AppInfo__as__desc, AppInfo.id AS AppInfo__as__id
//         , AppInfo.name AS AppInfo__as__name
// FROM LoginInfo 
//         LEFT JOIN UserInfo  ON LoginInfo.uid = UserInfo.id
//         JOIN AppInfo  ON LoginInfo.appid = AppInfo.id
// WHERE LoginInfo.id = 2	

// SELECT "logininfo"."location" AS "logininfo__as__location", "logininfo"."id" AS "logininfo__as__id", "logininfo"."appid" AS "logininfo__as__appid", "logininfo"."uid" AS "logininfo__as__uid", "logininfo"."update_time" AS "logininfo__as__update_time"
//         , "logininfo"."create_time" AS "logininfo__as__create_time", "userinfo"."nickname" AS "userinfo__as__nickname", "userinfo"."age" AS "userinfo__as__age", "userinfo"."id" AS "userinfo__as__id", "appinfo"."desc" AS "appinfo__as__desc"
//         , "appinfo"."id" AS "appinfo__as__id", "appinfo"."available" AS "appinfo__as__available", "appinfo"."name" AS "appinfo__as__name"
// FROM "logininfo"
//         LEFT JOIN "userinfo" ON "logininfo"."uid" = "userinfo"."id"
//         JOIN "appinfo" ON "logininfo"."appid" = "appinfo"."id"
// WHERE "logininfo"."id" = 2
// ORDER BY "logininfo"."id" DESC
}

    // auto query6 = em.createQuery!(UserInfo,
    // 		AppInfo)(" select a , b from UserInfo a left join AppInfo b on a.id = b.id limit 2;");
    // foreach (UserInfo d; query6.getResultList())
    // {
    // 	logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
    //     IDCard card = d.card;
    //     if(card is null) {
    //         warning("xxxx");
    //     }
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


void test_eql_select_with_join(EntityManager em)
{
    
    // Case 1
    // {
    //     string queryString = "select a, b from UserInfo a left join IDCard b on a.id = b.uid " ~ 
    //         " where a.age = 5";
    //     EqlQuery!(UserInfo) query = em.createQuery!(UserInfo)(queryString);

    //     foreach (UserInfo d; query.getResultList())
    //     {
    //         logDebug("UserInfo( %s , %s , %s ) ".format(d.id, d.nickName, d.age));
    //         IDCard card = d.card;
    //         warningf("card is null: %s", card is null);
    //         assert(card !is null);
    //          warningf("CardInfo, id: %s, desc: %s", card.id, card.desc);
    //     }

    // }

    // Case 2
    {
        string queryString = "select a, b from IDCard a left join UserInfo b on a.uid = b.id " ~ 
            " where b.age = 5";
        EqlQuery!(IDCard) query = em.createQuery!(IDCard)(queryString);

        foreach (IDCard card; query.getResultList())
        {
            
             warningf("CardInfo, id: %s, desc: %s", card.id, card.desc);

            UserInfo user = card.user;
            if(user is null) {
                warning("user is null");
            } else {
                logDebug("UserInfo( %s , %s , %s ) ".format(user.id, user.nickName, user.age));
            }

            assert(user !is null);
        }
    }

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

// UPDATE appinfo
// SET "desc" = 'test'
// WHERE "appinfo"."id" = 1

    // UPDATE AppInfo 
    // SET AppInfo.desc = 'test'
    // WHERE AppInfo.id = 1
}

// void test_eql_update(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	/// update statement
// 	auto update = em.createQuery!(UserInfo)(" update UserInfo u set u.age = u.id, u.nickName = 'dd' where  " ~ 
// 		"u.age > 2 and u.age < :age2 and u.id = :id and u.nickName = :name " ); 
// 		// update UserInfo u set u.age = 5 where u.id = 2

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
// 	auto del = em.createQuery!(UserInfo)(" delete from UserInfo u where u.id = 3 "); 
// 	// del.setParameter(1,3);
// 	logDebug(" del result : ",del.exec());
// }

void test_eql_insert(EntityManager em)
{
    mixin(DO_TEST);
    /// insert statement
    // string sqlString = "INSERT INTO UserInfo u(u.nickName,u.age) values (:name,:age) RETURNING id;";
    string sqlString = "INSERT INTO UserInfo u(u.nickName,u.age) values (:name,:age)";
    // string sqlString = "INSERT INTO UserInfo u(u.nickName,u.age) values (:name,:age);";
    EqlQuery!UserInfo insert = em.createQuery!(UserInfo)(sqlString); 
    insert.setParameter("name","momomo");
    insert.setParameter("age",22);

    logDebug(" insert result : ",insert.exec());
    warningf(" last id: %d", insert.lastInsertId());
}

// void test_eql_insert2(EntityManager em)
// {
// 	mixin(DO_TEST);
// 	/// insert statement
// 	auto insert = em.createQuery!(UserInfo)("  INSERT INTO UserInfo u(u.nickName,u.age) values (?,?)"); 
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


void test_EntityRepository_Insert(EntityManager em)
{
    mixin(DO_TEST);

    // case 1
    // EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

    // LoginInfo loginInfo = new LoginInfo();
    // loginInfo.location = "new location";

    // rep.insert(loginInfo);

    // tracef("new id: %d", loginInfo.id);
    // assert(loginInfo.id > 0);

    // case 2
    // insert with reserved word
    // EntityRepository!(AppInfo, int) rep = new EntityRepository!(AppInfo, int)(em);

    // AppInfo appInfo = new AppInfo();
    // appInfo.name = "no name";
    // // rep.insert(appInfo);
    // rep.save(appInfo);
    // tracef("new id: %d", appInfo.id);   

    // case 3
    EntityRepository!(UserInfo, int) rep = new EntityRepository!(UserInfo, int)(em);

    UserInfo userInfo = new UserInfo();
    userInfo.nickName = "Bob";
    rep.insert(userInfo);
    // rep.save(userInfo);
    tracef("new id: %d", userInfo.id); 

    // case 4
    // EntityRepository!(Agent, ulong) rep = new EntityRepository!(Agent, ulong)(em);

    // Agent a = new Agent();
    // a.username = "u1";
    // a.name = "xxxx";
    // rep.insert(a);
}

void test_EntityRepository_Save(EntityManager em)
{
    mixin(DO_TEST);

    // case 1
    // EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

    // LoginInfo loginInfo = rep.findById(1);
    // warning("LoginInfo(id: %d, uid: %d, updated: %d); Uinfo( %s) ".format(loginInfo.id, 
    //     loginInfo.uid, loginInfo.updated, loginInfo.uinfo));

    // loginInfo.appid += 1;
    // loginInfo.updated += 1;
    // rep.save(loginInfo);
    // LoginInfo newInfo = rep.findById(1);
    // logDebug("Uinfo(id: %d, updated: %d, Uinfo( %s) ".format(newInfo.id, newInfo.updated, loginInfo.uinfo));

    // case 2
    EntityRepository!(Agent, ulong) rep = new EntityRepository!(Agent, ulong)(em);
    Agent info = rep.findById(1);
    info.username = "test1";
    rep.save(info);

}


void test_EntityRepository_Save_with_reserved_word(EntityManager em)
{
    mixin(DO_TEST);

    EntityRepository!(AppInfo, int) rep = new EntityRepository!(AppInfo, int)(em);

    AppInfo info = rep.findById(1);
    infof("AppInfo(id: %d, desc: %s, available: %s) ".format(info.id, info.desc, info.isAvailable));

    info.desc = "test1";
    rep.save(info);	

    // UPDATE "appinfo"
    // SET "desc" = 'test1', "available" = true, "name" = 'Vitis'
    // WHERE "appinfo"."id" = 1    
    
    // info = rep.findById(1);
    // warning("AppInfo(id: %d, desc: %s) ".format(info.id, info.desc));
}

void testRepositoryWithTransaction(EntityManager em) {
    em.getTransaction().begin();

    EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

    LoginInfo loginInfo = rep.findById(1);
    warning("LoginInfo(id: %d, uid: %d, updated: %d); Uinfo( %s) ".format(loginInfo.id, 
        loginInfo.uid, loginInfo.updated, loginInfo.uinfo));

    auto update = em.createQuery!(UserInfo)(" update UserInfo u set u.age = u.id, u.nickName = 'dd' where  " ~ 
        "u.age > 2 and u.id = :id and u.nickName = :name " ); 
        // update UserInfo u set u.age = 5 where u.id = 2

    update.setParameter("age",2);
    // update.setParameter("age2",55); // and u.sex < :age2 // bug test
    update.setParameter("id",1);
    update.setParameter("name","tom");
    try {
        auto s = update.exec();
        warning(" update result : ", s);
        // warning(" update result : ",update.exec());  // Warning: The exception will be catched by logger
        // assert(false, "Never run to here");
        em.getTransaction().commit();
    } catch(Exception ex) {
        warning("An exception");
        em.getTransaction().rollback();
    }


    EntityRepository!(AppInfo, int) appRep = new EntityRepository!(AppInfo, int)(em);

    AppInfo appInfo = appRep.findById(1);
    infof("AppInfo(id: %d, desc: %s, available: %s) ".format(appInfo.id, appInfo.desc, appInfo.isAvailable));
}

void testRepositoryWithTransaction2(EntityManager em) {
    em.getTransaction().begin();

    EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

    LoginInfo loginInfo = rep.findById(1);
    warning("LoginInfo(id: %d, uid: %d, updated: %d); Uinfo( %s) ".format(loginInfo.id, 
        loginInfo.uid, loginInfo.updated, loginInfo.uinfo));

    auto update = em.createQuery!(UserInfo)(" update UserInfo u set u.age = u.id, u.nickName = 'dd' where  " ~ 
        "u.age > 2 and u.sex < :age2 and u.id = :id and u.nickName = :name " ); 
        // update UserInfo u set u.age = 5 where u.id = 2

    update.setParameter("age",2);
    update.setParameter("age2",55);
    update.setParameter("id",1);
    update.setParameter("name","tom");
    try {
        auto s = update.exec();
        warning(" update result : ", s);
        // warning(" update result : ",update.exec());  // Warning: The exception will be catched by logger
    } catch(Exception ex) {
        warning("An exception");
    }

    em.getTransaction().commit();

    EntityRepository!(AppInfo, int) appRep = new EntityRepository!(AppInfo, int)(em);

    AppInfo appInfo = appRep.findById(1);
    infof("AppInfo(id: %d, desc: %s, available: %s) ".format(appInfo.id, appInfo.desc, appInfo.isAvailable));
}

void test_EntityRepository_Count(EntityManager em)
{
    mixin(DO_TEST);

    EntityRepository!(LoginInfo, int) rep = new EntityRepository!(LoginInfo, int)(em);

    // LoginInfo.update_time 
    warningf("'updated' field: %s", rep.field().updated);

    long count = rep.count();
    tracef("count by id: %d", count);

    count = rep.count(LoginInfo.updated.stringof);
    tracef("count by location: %d", count);
}


void test_EntityRepository_Sum(EntityManager em)
{
    mixin(DO_TEST);

    EntityRepository!(UserInfo, int) rep = new EntityRepository!(UserInfo, int)(em);

    long sum = rep.sum(UserInfo.age.stringof);
    tracef("sum: %d", sum);
}

void testBinarySerializationForModel() {
    import hunt.serialization.BinarySerialization;
    // {
    //     Car car = new Car();
    //     car.name = "Ferrari";
    //     car.id = 123;

    //     ubyte[] buffer = serialize!(SerializationOptions.OnlyPublicWithNull)(car);
    //     tracef("%(%02X %)", buffer);
    //     Car newCar = unserialize!(Car, SerializationOptions.OnlyPublicWithNull)(buffer);
    //     tracef(newCar.name);
    // }


    {
        Car car1 = new Car();
        car1.name = "Ferrari";
        car1.id = 11;

        Car car2 = new Car();
        car2.name = "BMW";
        car2.id = 22;

        Car[] cars = [car1, car2];


        ubyte[] buffer = serialize!(SerializationOptions.OnlyPublicWithNull)(cars);
        tracef("%(%02X %)", buffer);
        Car[] newCars = unserialize!(Car[], SerializationOptions.OnlyPublicWithNull)(buffer);

        trace(newCars.length);
        assert(newCars.length == 2);

        foreach(Car c; newCars) {
            assert(c !is null);
            tracef(c.name);
        }
    }    
}


void testJsonSerializationForModel() {
    Car car = new Car();
    car.name = "Ferrari";
    car.id = 123;

    import hunt.serialization.Common;
    import hunt.serialization.JsonSerializer;

    JSONValue jv = JsonSerializer.toJson!(SerializationOptions.OnlyPublicWithNull)(car);
    string json = jv.toPrettyString();
    tracef(json);

    auto itemPtr = "_manager" in jv;
    assert(itemPtr is null);

    Car newCar = JsonSerializer.toObject!(Car, SerializationOptions.OnlyPublicWithNull)(jv);
    tracef(newCar.name);

}



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


EntityOption getMysqlDevOptions() {

    EntityOption option = new EntityOption();
    option.database.driver = "mysql";
    option.database.host = "10.1.223.222";
    option.database.port = 3306;
    option.database.database = "eql_test";
    option.database.username = "root";
    option.database.password = "123456789";
    option.database.prefix = "";

    return option;
}

EntityOption getPgOptions() {

    EntityOption option = new EntityOption();
    option.database.driver = "postgresql";
    option.database.host = "10.1.11.44";
    option.database.port = 5432;
    option.database.database = "eql_test";
    option.database.username = "postgres";
    option.database.password = "123456";	

    return option;
}

EntityOption getPgDevOptions() {

    EntityOption option = new EntityOption();
    option.database.driver = "postgresql";
    option.database.host = "10.1.223.222";
    option.database.port = 5432;
    option.database.database = "postgres";
    option.database.username = "postgres";
    option.database.password = "123456";	
    // option.database.username = "putao";
    // option.database.password = "putao123";	

    return option;
}

