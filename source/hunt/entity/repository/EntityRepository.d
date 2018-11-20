/*
 * Entity - Entity is an object-relational mapping tool for the D programming language. Referring to the design idea of JPA.
 *
 * Copyright (C) 2015-2018  Shanghai Putao Technology Co., Ltd
 *
 * Developer: HuntLabs.cn
 *
 * Licensed under the Apache-2.0 License.
 *
 */
 
module hunt.entity.repository.EntityRepository;

import hunt.entity;
import hunt.entity.repository.CrudRepository;
import hunt.entity.DefaultEntityManagerFactory;

public import hunt.entity.domain;

class EntityRepository (T, ID) : CrudRepository!(T, ID)
{
    this(EntityManager manager = null) {
        super(manager);
    }

    static string initObjects()
    {
        return `
        auto em = _manager ? _manager : createEntityManager();
        scope(exit) {if (!_manager) em.close();}
        CriteriaBuilder builder = em.getCriteriaBuilder();
        auto criteriaQuery = builder.createQuery!T;
        Root!T root = criteriaQuery.from();`;
    }
 

    alias count =  CrudRepository!(T, ID).count;
    alias findAll = CrudRepository!(T, ID).findAll;
   
    long count(Condition condition)
    {
        mixin(initObjects);

        criteriaQuery.select(builder.count(root)).where(condition.toPredicate());
        
        Long result = cast(Long)(em.createQuery(criteriaQuery).getSingleResult());
        return result.longValue();
    }


    long count(Specification!T specification)
    {
        mixin(initObjects);

        criteriaQuery.select(builder.count(root)).where(specification.toPredicate(
                root , criteriaQuery , builder));
        
        Long result = cast(Long)(em.createQuery(criteriaQuery).getSingleResult());
        return result.longValue();
    }

    T find(Condition condition)
    {
        auto list = findAll(condition);
        if(list.length > 0)
            return list[0];
        return null;
    }

    T find(ID id)
    {
        return this.findById(id);
    }

    T[] findAll(Sort sort)
    {
        mixin(initObjects);

        //sort
        foreach(o ; sort.list)
            criteriaQuery.getQueryBuilder().orderBy( o.getColumn() ~ " " ~ o.getOrderType());

        //all
        criteriaQuery.select(root);

        TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
        auto res = typedQuery.getResultList();

        

        return res;
    }

    T[] findAll(Condition condition)
    {
        mixin(initObjects);

        //specification
        criteriaQuery.select(root).where(condition.toPredicate());

        TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
        auto res = typedQuery.getResultList();

        return res;
    }

     T[] findAll(R)(Comparison!R condition)
    {
        mixin(initObjects);

        //specification
        criteriaQuery.select(root).where(condition);

        TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
        auto res = typedQuery.getResultList();

        return res;
    }

    T[] findAll(Specification!T specification)
    {
        mixin(initObjects);

        //specification
        criteriaQuery.select(root).where(specification.toPredicate(
                root , criteriaQuery , builder));

        TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
        auto res = typedQuery.getResultList();

        return res;
    }

    T[] findAll(Condition condition , Sort sort)
    {
        mixin(initObjects);

        //sort
        foreach(o ; sort.list)
            criteriaQuery.getQueryBuilder().orderBy( o.getColumn() ~ " " ~ o.getOrderType());

        //specification
        criteriaQuery.select(root).where(condition.toPredicate());

        TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
        auto res = typedQuery.getResultList();

        return res;
    }

    T[] findAll(Specification!T specification , Sort sort)
    {
        mixin(initObjects);

        //sort
        foreach(o ; sort.list)
            criteriaQuery.getQueryBuilder().orderBy(o.getColumn() ~ " " ~ o.getOrderType());

        //specification
        criteriaQuery.select(root).where(specification.toPredicate(
            root , criteriaQuery , builder));

        TypedQuery!T typedQuery = em.createQuery(criteriaQuery);
        auto res = typedQuery.getResultList();

        

        return res;
    }

    Page!T findAll(Pageable pageable)
    {
        mixin(initObjects);

        //sort
        foreach(o ; pageable.getSort.list)
            criteriaQuery.getQueryBuilder().orderBy(o.getColumn() ~ " " ~ o.getOrderType());

        //all
        criteriaQuery.select(root);

        //page
        TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
            .setMaxResults(pageable.getPageSize());

        auto res = typedQuery.getResultList();
        auto page = new Page!T(res, pageable, super.count());

        

        return page;
    }

    ///
    Page!T findAll(Condition condition, Pageable pageable)
    {
        mixin(initObjects);

        //sort
        foreach(o ; pageable.getSort.list)
            criteriaQuery.getQueryBuilder().orderBy(o.getColumn() ~ " " ~ o.getOrderType());


        //condition
        criteriaQuery.select(root).where(condition.toPredicate());
                
        //page
        TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
            .setMaxResults(pageable.getPageSize());
        auto res = typedQuery.getResultList();
        auto page = new Page!T(res, pageable, count(condition));

        

        return page;
    }

    Page!T findAll(Specification!T specification, Pageable pageable)
    {
        mixin(initObjects);

        //sort
        foreach(o ; pageable.getSort.list)
            criteriaQuery.getQueryBuilder().orderBy( o.getColumn() ~ " " ~ o.getOrderType());

        //specification
        criteriaQuery.select(root).where(specification.toPredicate(
            root , criteriaQuery , builder));
                
        //page
        TypedQuery!T typedQuery = em.createQuery(criteriaQuery).setFirstResult(pageable.getOffset())
            .setMaxResults(pageable.getPageSize());
        auto res = typedQuery.getResultList();
        auto page = new Page!T(res, pageable, count(specification));

        

        return page;
    }

    @property Member!T Field()
    {
        auto em = _manager ? _manager : createEntityManager();
        scope(exit) {if (!_manager) em.close();}
        return new Member!T(em);
    }

private:

    Member!T _member;
 
}


/*
version(unittest)
{
	@Table("p_menu")
	class Menu  
	{
        mixin MakeModel;

		@PrimaryKey
		@AutoIncrement
		int 		ID;

		@Column("name")
		string 		name;
        @JoinColumn("up_menu_id")
		int 		up_menu_id;
		string 		perident;
		int			index;
		string		icon;
		bool		status;
	}
}

unittest{

	void test_entity_repository()
	{
		
            //data
            
 //       (1, 'User', 0, 'user.edit', 0, 'fe-box', 0),
 //       (2, 'Role', 0, 'role.edit', 0, 'fe-box', 0),
 //       (3, 'Module', 0, 'module.edit', 0, 'fe-box', 0),
 //       (4, 'Permission', 0, 'permission.edit', 0, 'fe-box', 0),
 //       (5, 'Menu', 0, 'menu.edit', 0, 'fe-box', 0),
 //       (6, 'Manage User', 1, 'user.edit', 0, '0', 0),
 //       (7, 'Add User', 1, 'user.add', 0, '0', 0),
 //       (8, 'Manage Role', 2, 'role.edit', 0, '0', 0),
 //       (9, 'Add Role', 2, 'role.add', 0, '0', 0),
 //       (10, 'Manage Module', 3, 'module.edit', 0, '0', 0),
 //       (11, 'Add Module', 3, 'module.add', 0, '0', 0),
 //       (12, 'Manage Permission', 4, 'permission.edit', 0, '0', 0),
 //       (13, 'Add Permission', 4, 'permission.add', 0, '0', 0),
 //       (14, 'Manage Menu', 5, 'menu.edit', 0, '0', 0),
 //       (15, 'Add Menu', 5, 'menu.add', 0, '0', 0);
            

        auto option = new EntityOption;

        option.database.driver = "mysql";
        option.database.host = "127.0.0.1";
        option.database.port = 3306;
        option.database.database = "hunt_test";
        option.database.username = "root";
        option.database.password = "123456";
        option.database.charset = "utf8mb4";
        option.database.prefix = "";

        EntityManagerFactory entityManagerFactory = Persistence.createEntityManagerFactory("default", option);
        EntityManager em = entityManagerFactory.createEntityManager();

		auto rep = new EntityRepository!(Menu , int)(em);
		
		//sort
		auto menus1 = rep.findAll(new Sort(rep.Field.ID , OrderBy.DESC));
		assert(menus1.length == 15);
		assert(menus1[0].ID == 15 && menus1[$ - 1].ID == 1);
		
		//specification
		class MySpecification: Specification!Menu
		{
			Predicate toPredicate(Root!Menu root, CriteriaQuery!Menu criteriaQuery ,
				CriteriaBuilder criteriaBuilder)
			{
				Predicate _name = criteriaBuilder.gt(root.Menu.ID, 5);
				return criteriaBuilder.and(_name);
			}
		}
		auto menus2 = rep.findAll(new MySpecification());
		assert(menus2.length == 10);
		assert(menus2[0].ID == 6);
		
		//sort specification
		auto menus3 = rep.findAll(new MySpecification , new Sort(rep.Field.ID ,OrderBy.DESC));
		assert(menus3[0].ID == 15 && menus3[$ - 1].ID == 6);

		//page
		auto pages1 = rep.findAll(new Pageable(0 , 10 , rep.Field.ID , OrderBy.DESC));
		assert(pages1.getTotalPages() == 2);
		assert(pages1.getContent.length == 10);
		assert(pages1.getContent[0].ID == 15 && pages1.getContent[$-1].ID == 6);
		assert(pages1.getTotalElements() == 15);

		//page specification
		auto pages2 = rep.findAll(new MySpecification , new Pageable(1 , 5 , rep.Field.ID , OrderBy.DESC));
		assert(pages2.getTotalPages() == 2);
		assert(pages2.getContent.length == 5);
		assert(pages2.getContent[0].ID == 10 && pages1.getContent[$-1].ID == 6);
		assert(pages2.getTotalElements() == 10);

        ///where name == "User"   
        auto condition = new Condition(`%s = '%s'` , rep.Field.name , "User");
        auto menu4 = rep.find(condition);
        assert(menu4.ID == 1);

        ///count
        assert(rep.count(new Condition(`%s > %d` , rep.Field.ID , 0)) == 15);


    }


	test_entity_repository();
}*/