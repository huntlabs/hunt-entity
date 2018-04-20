


import entity;

import std.stdio;




@Table("user")
class User : Entity
{
    @AutoIncrement @PrimaryKey 
    int id;

    
    string name;
    double money;
    string email;
    bool status;

}




void main() {
    
    DatabaseConfig config = new DatabaseConfig("mysql://dev:111111@10.1.11.31:3306/blog?charset=utf-8");
    EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("mysql",config);
    EntityManager entitymanager = entityManagerFactory.createEntityManager();

    entitymanager.getTransaction().begin();


    
    CriteriaBuilder criteriaBuilder = entitymanager.getCriteriaBuilder();
    


    Predicate condition;
    TypedQuery!User typedQuery;
    Query!User query;
    Root!User criteriaUser;
    User user;

    //test 


    //test CriteriaUpdate
    CriteriaUpdate!User criteriaUpdate = criteriaBuilder.createCriteriaUpdate!(User);
    criteriaUser = criteriaUpdate.from();
    condition = criteriaBuilder.equal(criteriaUser.User.id, 26805);
    criteriaUpdate.where(condition);
    criteriaUpdate.set(criteriaUser.User.name, "joker");
    query = entitymanager.createQuery(criteriaUpdate);
    int updaterows = query.executeUpdate();
    log("update rows = ", updaterows);


    //test CriteriaQuery
    CriteriaQuery!User criteriaQuery = criteriaBuilder.createQuery!(User);
    criteriaUser = criteriaQuery.from();
    condition = criteriaBuilder.equal(criteriaUser.User.id, 26805);
    typedQuery = entitymanager.createQuery(criteriaQuery.select(criteriaUser).where(condition));
    user = typedQuery.getSingleResult();
    User[] users = typedQuery.getResultList();
    log("user.name = ", user.name);
    foreach(k,v; users) {
        log("users[%s].name = %s".format(k, v.name));
    }

    //test criteriaDelete
    CriteriaDelete!User criteriaDelete = criteriaBuilder.createCriteriaDelete!(User);
    criteriaUser = criteriaDelete.from();
    Predicate ep = criteriaBuilder.equal(criteriaUser.User.id, user.id);
    Predicate cp = criteriaBuilder.equal(criteriaUser.User.name, "hakar11");
    Query!User deleteQuery = entitymanager.createQuery(criteriaDelete.where(criteriaBuilder.and(ep,cp)));
    int rows = deleteQuery.executeUpdate();
    log("delete rows = ", rows);


    //test entity persist
    User entityUser = new User();
    entityUser.name = "hakar11";
    entityUser.email = "hakar@163.com";
    entityUser.money = 102;
    entitymanager.persist(entityUser);
    log("insert id = ", entityUser.id);

    //test entity find
    string name;
    name = entitymanager.find!(User)(entityUser.id).name;
    log("name = ", name);
    name = entitymanager.find!(User)(entityUser).name;
    log("name = ", name);

    //test entity merge
    // entitymanager.merge();

    //test entity remove
    int ret = entitymanager.remove!(User)(entityUser);
    log("remove lines = ", ret);


    entitymanager.getTransaction().commit();
    // entitymanager.getTransaction().rollback();

    entitymanager.close();
    entityManagerFactory.close();

    


}