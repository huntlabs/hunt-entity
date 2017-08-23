module entity.entity.persistence;

import entity;

class Persistence
{
	public static EntityManagerFactory createEntityManagerFactory(string name,
			DatabaseOption option)
	{
		assert(name);
		return new EntityManagerFactory(name,option);
	}
}
