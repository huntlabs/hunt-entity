module entity.DefaultEntityManagerFactory;

import entity.EntityManagerFactory;

private EntityManagerFactory _defaultEntityManagerFactory;

@property EntityManagerFactory defaultEntityManagerFactory()
{
	if (null == _defaultEntityManagerFactory)
	{
		// error
		return null;
	}

	return _defaultEntityManagerFactory;
}

set setDefaultEntityManagerFactory(EntityManagerFactory factory)
{
	_defaultEntityManagerFactory = factory;
}
