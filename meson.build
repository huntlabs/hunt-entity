project('hunt-entity', 'd',
    meson_version: '>=0.46',
    license: 'Apache-2.0',

    version: '2.0.2'
)

project_soversion = '0'
hdb_required_version = '>= 1.0.1'
hunt_sql_required_version = '>= 1.0.1'


src_dir = include_directories('source/')
pkgc = import('pkgconfig')

entity_src = [
    'source/hunt/entity/Constant.d',
    'source/hunt/entity/criteria/CriteriaBase.d',
    'source/hunt/entity/criteria/CriteriaBuilder.d',
    'source/hunt/entity/criteria/CriteriaDelete.d',
    'source/hunt/entity/criteria/CriteriaQuery.d',
    'source/hunt/entity/criteria/CriteriaUpdate.d',
    'source/hunt/entity/criteria/Join.d',
    'source/hunt/entity/criteria/Long.d',
    'source/hunt/entity/criteria/Order.d',
    'source/hunt/entity/criteria/package.d',
    'source/hunt/entity/criteria/Predicate.d',
    'source/hunt/entity/criteria/Root.d',
    'source/hunt/entity/DefaultEntityManagerFactory.d',
    'source/hunt/entity/domain/Condition.d',
    'source/hunt/entity/domain/Member.d',
    'source/hunt/entity/domain/package.d',
    'source/hunt/entity/domain/Pageable.d',
    'source/hunt/entity/domain/Page.d',
    'source/hunt/entity/domain/Sort.d',
    'source/hunt/entity/domain/Specification.d',
    'source/hunt/entity/EntityCreateTable.d',
    'source/hunt/entity/Entity.d',
    'source/hunt/entity/EntityException.d',
    'source/hunt/entity/EntityExpression.d',
    'source/hunt/entity/EntityFieldInfo.d',
    'source/hunt/entity/EntityFieldManyToMany.d',
    'source/hunt/entity/EntityFieldManyToOne.d',
    'source/hunt/entity/EntityFieldNormal.d',
    'source/hunt/entity/EntityFieldObject.d',
    'source/hunt/entity/EntityFieldOneToMany.d',
    'source/hunt/entity/EntityFieldOneToOne.d',
    'source/hunt/entity/EntityFieldOwner.d',
    'source/hunt/entity/EntityFieldManyToMany.d',
    'source/hunt/entity/EntityFieldManyToManyOwner.d',
    'source/hunt/entity/EntityInfo.d',
    'source/hunt/entity/EntityManager.d',
    'source/hunt/entity/EntityManagerFactory.d',
    'source/hunt/entity/EntityOption.d',
    'source/hunt/entity/EntitySession.d',
    'source/hunt/entity/EntityTransaction.d',
    'source/hunt/entity/package.d',
    'source/hunt/entity/Persistence.d',
    'source/hunt/entity/Query.d',
    'source/hunt/entity/repository/CrudRepository.d',
    'source/hunt/entity/repository/EntityRepository.d',
    'source/hunt/entity/repository/package.d',
    'source/hunt/entity/repository/Repository.d',
    'source/hunt/entity/TypedQuery.d',
    'source/hunt/entity/utils/Common.d',
    'source/hunt/entity/eql/EqlCache.d',
    'source/hunt/entity/eql/EqlInfo.d',
    'source/hunt/entity/eql/EqlParse.d',
    'source/hunt/entity/eql/EqlQuery.d',
    'source/hunt/entity/eql/ResultDes.d',
    'source/hunt/entity/eql/package.d',
    'source/hunt/entity/NativeQuery.d'
]
install_subdir('source/hunt/', install_dir: 'include/d/hunt-entity/')

enabled_drivers = get_option('drivers')

# try to find required dependencies on the system
native_dep_found = true
if enabled_drivers.contains('postgres')
    hdb_postgres_dep = dependency('hunt-database-postgres', version: hdb_required_version, required: false)
    native_dep_found = native_dep_found? hdb_postgres_dep.found() : false
endif

if enabled_drivers.contains('mysql')
    hdb_mysql_dep = dependency('hunt-database-mysql', version: hdb_required_version, required: false)
    native_dep_found = native_dep_found? hdb_mysql_dep.found() : false
endif

if enabled_drivers.contains('sqlite')
    hdb_sqlite_dep = dependency('hunt-database-sqlite', version: hdb_required_version, required: false)
    native_dep_found = native_dep_found? hdb_sqlite_dep.found() : false
endif

if enabled_drivers.contains('multi')
    hdb_multi_dep = dependency('hunt-database-multi', version: hdb_required_version, required: false)
    native_dep_found = native_dep_found? hdb_multi_dep.found() : false
endif

if not native_dep_found
    # native dependency is missing, let's try a subproject
    hdb_prj = subproject('hunt-database',
                         version: hdb_required_version,
                         default_options: ['drivers=' + ','.join(enabled_drivers)]
              )

    if enabled_drivers.contains('postgres')
        hdb_postgres_dep = hdb_prj.get_variable('hdb_postgres_dep')
    endif

    if enabled_drivers.contains('mysql')
        hdb_mysql_dep = hdb_prj.get_variable('hdb_mysql_dep')
    endif

    if enabled_drivers.contains('sqlite')
        hdb_sqlite_dep = hdb_prj.get_variable('hdb_sqlite_dep')
    endif

    if enabled_drivers.contains('multi')
        hdb_multi_dep = hdb_prj.get_variable('hdb_multi_dep')
    endif

endif

hunt_sql_prj = subproject('hunt-sql',
                         version: hunt_sql_required_version
              )

# determine the right version flag for the compiler we use
dc = meson.get_compiler('d')
dc_version_arg = '-fversion='
if dc.get_id() == 'llvm'
    dc_version_arg = '-d-version='
elif dc.get_id() == 'dmd'
    dc_version_arg = '-version='
endif

# construct a bunch of libraries for each selected driver
foreach driver : get_option('drivers')
    if driver == 'postgres'
        lib_deps = [hdb_postgres_dep]
        pkgc_deps = ['hunt-database-postgres']

        lib_name = 'hunt-entity-postgres'
        version_flags = ['USE_POSTGRESQL']
        lib_description = 'Object-relational mapping tool for D, similar to JPA - Built for PostgreSQL.'


    elif driver == 'mysql'
        lib_deps = [hdb_mysql_dep]
        pkgc_deps = ['hunt-database-mysql']

        lib_name = 'hunt-entity-mysql'
        version_flags = ['USE_MYSQL']
        lib_description = 'Object-relational mapping tool for D, similar to JPA - Built for MySQL.'

    elif driver == 'sqlite'
        lib_deps = [hdb_sqlite_dep]
        pkgc_deps = ['hunt-database-sqlite']

        lib_name = 'hunt-entity-sqlite'
        version_flags = ['USE_SQLITE']
        lib_description = 'Object-relational mapping tool for D, similar to JPA - Built for SQLite.'

    elif driver == 'multi'
        lib_deps = [hdb_multi_dep]
        pkgc_deps = ['hunt-database-multi']

        lib_name = 'hunt-entity-multi'
        version_flags = ['USE_POSTGRESQL', 'USE_MYSQL', 'USE_SQLITE']
        lib_description = 'Object-relational mapping tool for D, similar to JPA - Built for all supported database drivers.'

    else
        error('Unknown driver selected!')
    endif


    db_lib = library(lib_name,
        [entity_src],
        include_directories: [src_dir],
        dependencies: lib_deps,
        install: true,
        version: meson.project_version(),
        soversion: project_soversion,
        d_module_versions: version_flags
    )

    pkgc.generate(name: lib_name,
        libraries: db_lib,
        subdirs: 'd/hunt-entity/',
        requires: pkgc_deps,
        version: meson.project_version(),
        d_module_versions: version_flags,
        description: lib_description
    )

    ver_dc_args = []
    foreach v : version_flags
        ver_dc_args += [dc_version_arg + v]
    endforeach


    # this dumb code repetition exists to allow other Meson projects to embed this as subproject easily,
    # and to achieve that we need to declare dependencies with different variable names.
    if driver == 'postgres'
        hentity_postgres_dep = declare_dependency(
            link_with: [db_lib],
            dependencies: lib_deps,
            include_directories: [src_dir],
            compile_args: ver_dc_args
        )

    elif driver == 'mysql'
        hentity_mysql_dep = declare_dependency(
            link_with: [db_lib],
            dependencies: lib_deps,
            include_directories: [src_dir],
            compile_args: ver_dc_args
        )

    elif driver == 'sqlite'
        hentity_sqlite_dep = declare_dependency(
            link_with: [db_lib],
            dependencies: lib_deps,
            include_directories: [src_dir],
            compile_args: ver_dc_args
        )

    elif driver == 'multi'
        hentity_multi_dep = declare_dependency(
            link_with: [db_lib],
            dependencies: lib_deps,
            include_directories: [src_dir],
            compile_args: ver_dc_args
        )

    endif

endforeach
