module entity.repository.EntityRepository;

import entity.repository.CrudRepository;

abstract class EntityRepository (T, ID) : CrudRepository!(T, ID)
{
}
