module entity.Persistence;

import entity;

class Persistence {
    public static EntityManagerFactory createEntityManagerFactory(string name, DatabaseConfig config) {
		return new EntityManagerFactory(name,config);
	}
}