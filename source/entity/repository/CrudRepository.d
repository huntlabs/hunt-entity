module entity.repository.CrudRepository;

public import entity.repository.Repository;

abstract class CrudRepository(T, ID) : Repository!(T, ID)
{
    public long count()
    {
        return 0;
    }

    public void remove()
    {
    }

    public void deleteAll()
    {
    }
    
    public void deleteAll(T[] entities)
    {
    }

    public void deleteById(ID id)
    {
    }
    
    public bool existsById(ID id)
    {
    }

    public T[] findAll()
    {
        return [];
    }

    public T[] findAllById(ID[] ids)
    {
        return [];
    }

    public T findById(ID id)
    {
        return null;
    }

    public T save(T entity)
    {
        return null;
    }

    public T[] saveAll(T[] entities)
    {
        return [];
    }
}
